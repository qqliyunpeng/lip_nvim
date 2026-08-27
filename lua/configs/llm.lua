local M = {}

-- llm.nvim (Kurama622/llm.nvim)
--
-- This gateway is OpenAI-compatible but returns `choices[0].message.content = null` for
-- non-streaming responses, so WordTranslate must use streaming SSE.
function M.llmConfig()
    local function is_headless()
        return #vim.api.nvim_list_uis() == 0
    end

    -- Cursor-top floating "thinking" indicator (no notify, no translation popup).
    -- NOTE: Do NOT use llm.nvim built-in spinner here; keep this self-contained.
    local thinking = {
        box = nil,
        timer = nil,
        frame = 1,
    }

    local spinner_frames = { "-", "\\", "|", "/" }
    local window_translate_ns = vim.api.nvim_create_namespace("llm_window_translate_overlay")
    local window_translate_state = {}
    local word_translate_popup

    -- Make floating popups transparent (spinner + translation result).
    -- We use dedicated highlight groups and override them via `winhighlight`.
    local function apply_transparent_popup(win_opts)
        pcall(vim.api.nvim_set_hl, 0, "LlmPopupNormal", { bg = "NONE" })
        pcall(vim.api.nvim_set_hl, 0, "LlmPopupBorder", { bg = "NONE" })

        win_opts.win_options = vim.tbl_extend("force", win_opts.win_options or {}, {
            winhighlight = "Normal:LlmPopupNormal,NormalNC:LlmPopupNormal,FloatBorder:LlmPopupBorder",
        })
    end

    local function stop_thinking_timer()
        if thinking.timer then
            pcall(function()
                thinking.timer:stop()
                thinking.timer:close()
            end)
        end
        thinking.timer = nil
    end

    local function clear_thinking()
        if is_headless() then
            return
        end

        stop_thinking_timer()

        if thinking.box then
            pcall(function()
                ---@diagnostic disable-next-line: undefined-field
                thinking.box:unmount()
            end)
        end

        thinking.box = nil
        thinking.waiting_state = nil
        thinking.frame = 1
    end

    local function clear_window_translate_overlay(bufnr)
        pcall(vim.api.nvim_buf_clear_namespace, bufnr, window_translate_ns, 0, -1)
        pcall(function()
            vim.b[bufnr].llm_window_translate_overlay = false
        end)

        local st = window_translate_state[bufnr]
        if not st then
            return
        end

        if st.timer then
            pcall(function()
                st.timer:stop()
                st.timer:close()
            end)
        end
        if st.augroup then
            pcall(vim.api.nvim_del_augroup_by_id, st.augroup)
        end
        window_translate_state[bufnr] = nil
    end

    local function wrap_display_line(line, width)
        if line == "" then
            return { "" }
        end

        local wrapped = {}
        local cur = ""
        local cur_width = 0

        for i = 0, vim.fn.strchars(line) - 1 do
            local ch = vim.fn.strcharpart(line, i, 1)
            local ch_width = vim.fn.strdisplaywidth(ch)

            if cur ~= "" and cur_width + ch_width > width then
                wrapped[#wrapped + 1] = cur
                cur = ch
                cur_width = ch_width
            else
                cur = cur .. ch
                cur_width = cur_width + ch_width
            end
        end

        wrapped[#wrapped + 1] = cur
        return wrapped
    end

    local function wrap_display_lines(lines, width)
        local wrapped = {}
        for _, line in ipairs(lines) do
            vim.list_extend(wrapped, wrap_display_line(line, width))
        end
        return wrapped
    end

    local function window_translate_overlay_width(opts)
        local ok, win_width = pcall(vim.api.nvim_win_get_width, 0)
        local max_width = opts.overlay_max_width or 80
        return math.max(1, math.min(max_width, (ok and win_width or vim.o.columns) - 4))
    end

    local function window_visible_range()
        return vim.fn.line("w0"), vim.fn.line("w$")
    end

    local function paragraph_key(paragraph)
        return table.concat({
            tostring(paragraph.start_lnum),
            tostring(paragraph.end_lnum),
            paragraph.text_key,
        }, ":")
    end

    local function range_paragraphs(bufnr, top, bottom)
        local line_count = vim.api.nvim_buf_line_count(bufnr)
        top = math.max(1, math.min(top, line_count))
        bottom = math.max(top, math.min(bottom, line_count))

        while top > 1 do
            local line = vim.api.nvim_buf_get_lines(bufnr, top - 2, top - 1, false)[1] or ""
            if line:match("^%s*$") then
                break
            end
            top = top - 1
        end

        while bottom < line_count do
            local line = vim.api.nvim_buf_get_lines(bufnr, bottom, bottom + 1, false)[1] or ""
            if line:match("^%s*$") then
                break
            end
            bottom = bottom + 1
        end

        local source_lines = vim.api.nvim_buf_get_lines(bufnr, top - 1, bottom, false)
        local paragraphs = {}
        local cur = {}
        local start_lnum = nil

        for i, line in ipairs(source_lines) do
            if line:match("^%s*$") then
                if #cur > 0 then
                    paragraphs[#paragraphs + 1] = {
                        start_lnum = start_lnum,
                        end_lnum = top + i - 2,
                        indent = cur[1]:match("^%s*") or "",
                        text = table.concat(cur, "\n"),
                    }
                    cur = {}
                    start_lnum = nil
                end
            else
                if #cur == 0 then
                    start_lnum = top + i - 1
                end
                cur[#cur + 1] = line
            end
        end

        if #cur > 0 then
            paragraphs[#paragraphs + 1] = {
                start_lnum = start_lnum,
                end_lnum = bottom,
                indent = cur[1]:match("^%s*") or "",
                text = table.concat(cur, "\n"),
            }
        end

        for _, paragraph in ipairs(paragraphs) do
            paragraph.text_key = tostring(vim.fn.sha256(paragraph.text))
            paragraph.key = paragraph_key(paragraph)
        end

        return paragraphs, top, bottom
    end

    local function render_window_translation(bufnr, options, paragraph, translation)
        if not translation or translation == "" then
            return
        end

        local virt_lines = {}
        local lines = vim.split(translation, "\n", { plain = true, trimempty = true })
        local indent = paragraph.indent or ""
        local width = math.max(1, window_translate_overlay_width(options) - vim.fn.strdisplaywidth(indent))
        if indent ~= "" then
            for i, line in ipairs(lines) do
                lines[i] = line:gsub("^%s+", "")
            end
        end
        for _, line in ipairs(wrap_display_lines(lines, width)) do
            virt_lines[#virt_lines + 1] = {
                { indent .. line, "LlmWindowTranslateOverlay" },
            }
        end
        if #virt_lines == 0 then
            return
        end

        vim.api.nvim_buf_set_extmark(bufnr, window_translate_ns, paragraph.end_lnum - 1, 0, {
            virt_lines = virt_lines,
            priority = 1000,
        })
    end

    local function normalize_translation_compare(text)
        return (text or ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    end

    local function translation_same_as_source(paragraph, translation)
        return normalize_translation_compare(paragraph.text) == normalize_translation_compare(translation)
    end

    local function show_thinking()
        if is_headless() then
            return
        end

        -- If already shown, keep running.
        if thinking.box then
            return
        end

        local ui = require("llm.common.ui")
        local wait_box_opts = ui.wait_ui_opts()
        -- Force cursor-relative placement above cursor (without notify).
        wait_box_opts.relative = "cursor"
        wait_box_opts.position = { row = -1, col = 0 }
        apply_transparent_popup(wait_box_opts)

        ---@type nui_popup
        thinking.box = require("nui.popup")(wait_box_opts)

        ---@diagnostic disable-next-line: undefined-field
        thinking.box:mount()

        -- Render initial frame.
        ---@diagnostic disable-next-line: undefined-field
        pcall(vim.api.nvim_buf_set_lines, thinking.box.bufnr, 0, -1, false, {
            spinner_frames[thinking.frame],
        })

        -- Start our own spinner loop.
        local uv = vim.uv or vim.loop
        thinking.timer = uv.new_timer()
        thinking.timer:start(120, 120, function()
            vim.schedule(function()
                ---@diagnostic disable-next-line: undefined-field
                if not thinking.box or not thinking.box.bufnr or not vim.api.nvim_buf_is_valid(thinking.box.bufnr) then
                    clear_thinking()
                    return
                end
                thinking.frame = (thinking.frame % #spinner_frames) + 1
                ---@diagnostic disable-next-line: undefined-field
                pcall(vim.api.nvim_buf_set_lines, thinking.box.bufnr, 0, -1, false, {
                    spinner_frames[thinking.frame] .. " Thinking...",
                })
            end)
        end)
    end

    -- Streaming WordTranslate handler (silent when empty).
    local function word_translate_stream_handler(name, F, state, _, prompt, opts)
        if word_translate_popup and word_translate_popup.winid
            and vim.api.nvim_win_is_valid(word_translate_popup.winid) then
            vim.api.nvim_set_current_win(word_translate_popup.winid)
            return
        end
        word_translate_popup = nil

        local Popup = require("nui.popup")

        local options = {
            exit_on_move = true,
            enable_cword_context = true,
            apply_visual_selection = true,
            -- Auto resize result popup based on content.
            -- Can be disabled via opts.auto_resize = false.
            auto_resize = true,
            win_opts = {
                relative = "cursor",
                position = { row = 1, col = 0 },
                -- NOTE: `size` will be computed after we have the translated output.
                -- Users can still override it by passing opts.win_opts.size explicitly.
                border = { style = "rounded" },
                win_options = {
                    wrap = true,
                    linebreak = true,
                    spell = false,
                    number = false,
                    winhighlight = "Normal:LlmPopupNormal,NormalNC:LlmPopupNormal,FloatBorder:LlmPopupBorder",
                },
                buf_options = { buftype = "nofile", filetype = "llm" },
                zindex = 70,
            },
        }
        options = vim.tbl_deep_extend("force", options, opts or {})

        local function clamp(v, lo, hi)
            if v < lo then
                return lo
            end
            if v > hi then
                return hi
            end
            return v
        end

        local utf8_char_pattern = "[%z\1-\127\194-\244][\128-\191]*"

        local function wrap_display_line(line, width)
            if line == "" then
                return { "" }
            end

            local wrapped = {}
            local cur = ""
            local cur_width = 0

            for ch in line:gmatch(utf8_char_pattern) do
                local ch_width = vim.fn.strdisplaywidth(ch)

                if cur ~= "" and cur_width + ch_width > width then
                    wrapped[#wrapped + 1] = cur
                    cur = ch
                    cur_width = ch_width
                else
                    cur = cur .. ch
                    cur_width = cur_width + ch_width
                end
            end

            wrapped[#wrapped + 1] = cur
            return wrapped
        end

        local function wrap_display_lines(lines, width)
            local wrapped = {}
            for _, line in ipairs(lines) do
                vim.list_extend(wrapped, wrap_display_line(line, width))
            end
            return wrapped
        end

        local function compute_popup_layout(lines)
            local min_w = 8
            local ok_width, win_width = pcall(vim.api.nvim_win_get_width, 0)
            win_width = ok_width and win_width or vim.o.columns
            local ok_virtcol, virtcol = pcall(vim.fn.virtcol, ".")
            local cursor_col = ok_virtcol and math.max(0, virtcol - 1) or 0
            local available_width = math.max(min_w, win_width - cursor_col - 2)
            local max_w = math.max(min_w, math.min(available_width, math.floor(win_width * 0.7)))
            local min_h = 1
            local ok_height, win_height = pcall(vim.api.nvim_win_get_height, 0)
            local max_h = math.max(min_h, math.floor((ok_height and win_height or vim.o.lines) * 0.3))

            local widest = 0
            for _, l in ipairs(lines) do
                -- Use display width to handle multibyte chars (CJK, etc.).
                local w = vim.fn.strdisplaywidth(l)
                if w > widest then
                    widest = w
                end
            end

            -- Add a small padding so the text doesn't touch the border.
            local width = clamp(widest + 2, min_w, max_w)
            local wrapped = wrap_display_lines(lines, math.max(1, width - 2))
            local height = clamp(#wrapped, min_h, max_h)
            return width, height, wrapped
        end

        local content = ""
        if options.apply_visual_selection then
            local mode = options.mode or vim.fn.mode()
            local lines = F.GetVisualSelectionRange(vim.api.nvim_get_current_buf(), mode, options)
            content = F.GetVisualSelection(lines)
        end
        if content == "" and options.enable_cword_context then
            content = vim.fn.expand("<cword>")
        end
        if content == "" then
            return
        end

        local conf = require("llm.config").configs
        local url = options.url or conf.url
        local model = options.model or conf.model
        local key = conf.fetch_key and conf.fetch_key() or ""
        if key == "" then
            return
        end

        local body = {
            model = model,
            stream = true,
            temperature = options.temperature or conf.temperature or 0.3,
            max_tokens = options.max_tokens or conf.max_tokens or 1024,
            messages = {
                { role = "system", content = prompt },
                { role = "user", content = content },
            },
        }

        -- Persist for llm.nvim session tracking.
        state.app.session[name] = body.messages

        local tmp = vim.fn.tempname()
        vim.fn.writefile({ vim.json.encode(body) }, tmp)

        local acc = {}
        local stderr_acc = {}

        local function handle_sse_line(line)
            if type(line) ~= "string" or line == "" then
                return
            end

            local payload = line:match("^data:%s*(.*)$")
            if not payload or payload == "[DONE]" then
                return
            end

            local ok, decoded = pcall(vim.json.decode, payload)
            if not ok or type(decoded) ~= "table" then
                return
            end

            local choice = decoded.choices and decoded.choices[1]
            local delta = choice and choice.delta
            local t = delta and delta.content
            if t ~= nil and t ~= vim.NIL and t ~= "" then
                acc[#acc + 1] = t
            end
        end

        show_thinking()

        local job = vim.fn.jobstart({
            "curl",
            "-sS",
            "--fail-with-body",
            "-m",
            tostring(options.timeout or conf.timeout or 30),
            "-N",
            "-X",
            "POST",
            "-H",
            "Content-Type: application/json",
            "-H",
            "Authorization: Bearer " .. key,
            "-d",
            "@" .. tmp,
            url,
        }, {
            stdout_buffered = false,
            stderr_buffered = false,
            on_stdout = function(_, data, _)
                if type(data) ~= "table" then
                    return
                end
                for _, line in ipairs(data) do
                    handle_sse_line(line)
                end
            end,
            on_stderr = function(_, data, _)
                if type(data) ~= "table" then
                    return
                end
                for _, line in ipairs(data) do
                    if type(line) == "string" and line ~= "" then
                        stderr_acc[#stderr_acc + 1] = line
                    end
                end
            end,
            on_exit = function(_, code, _)
                pcall(vim.fn.delete, tmp)

                vim.schedule(function()
                    -- Ensure spinner is always cleared once the curl job exits.
                    -- (Even if creating/mounting the result popup fails.)
                    clear_thinking()

                    local out = table.concat(acc, "")
                    if out == "" then
                        local msg = {
                            "WordTranslate: empty output.",
                            "exit=" .. tostring(code),
                            "url=" .. tostring(url),
                            "model=" .. tostring(model),
                        }
                        if #stderr_acc > 0 then
                            msg[#msg + 1] = "\nstderr:\n" .. table.concat(stderr_acc, "\n")
                        end
                        vim.notify(table.concat(msg, "\n"), vim.log.levels.WARN)
                        return
                    end

                    local lines = vim.split(out, "\n", { plain = true })

                    if options.auto_resize ~= false and options.win_opts and options.win_opts.size == nil then
                        local width, height, wrapped = compute_popup_layout(lines)
                        options.win_opts.size = { width = width, height = height }
                        lines = wrapped
                    end

                    local ok_pop, pop = pcall(Popup, options.win_opts)
                    if not ok_pop or not pop then
                        return
                    end

                    local ok_mount = pcall(function()
                        pop:mount()
                        vim.api.nvim_buf_set_lines(pop.bufnr, 0, -1, false, lines)
                    end)
                    if not ok_mount then
                        pcall(function()
                            pop:unmount()
                        end)
                        return
                    end
                    word_translate_popup = pop

                    if options.exit_on_move then
                        vim.api.nvim_create_autocmd("CursorMoved", {
                            group = vim.api.nvim_create_augroup("llm_word_translate_exit_on_move", { clear = true }),
                            callback = function()
                                if pop.winid and vim.api.nvim_get_current_win() == pop.winid then
                                    return
                                end
                                if pop then
                                    pcall(function()
                                        pop:unmount()
                                    end)
                                    if word_translate_popup == pop then
                                        word_translate_popup = nil
                                    end
                                end
                            end,
                        })
                    end
                end)
            end,
        })

        if job <= 0 then
            clear_thinking()
        end

        F.VisMode2NorMode()
    end

    local function window_translate_overlay_handler(name, _, state, _, prompt, opts)
        local options = vim.tbl_deep_extend("force", {
            debounce_ms = 500,
            max_paragraphs_per_request = 6,
            min_new_paragraphs = 2,
            prefetch_lines = 10,
            scroll_threshold = 5,
            temperature = 0.3,
            max_tokens = 2048,
        }, opts or {})

        local bufnr = vim.api.nvim_get_current_buf()
        if vim.b[bufnr].llm_window_translate_overlay then
            clear_window_translate_overlay(bufnr)
            return
        end

        pcall(vim.api.nvim_set_hl, 0, "LlmWindowTranslateOverlay", { link = "Comment" })

        local conf = require("llm.config").configs
        local url = options.url or conf.url
        local model = options.model or conf.model
        local key = conf.fetch_key and conf.fetch_key() or ""
        if key == "" then
            return
        end

        local st = {
            app_state = state,
            enabled = true,
            in_flight = false,
            queued = false,
            rendered = {},
            translations = {},
            pending = {},
            timer = nil,
        }
        window_translate_state[bufnr] = st
        vim.b[bufnr].llm_window_translate_overlay = true

        local function start_request(paragraphs, top, bottom)
            st.in_flight = true
            st.queued = false
            st.last_request_top = top
            st.last_request_bottom = bottom

            local input = {}
            for i, paragraph in ipairs(paragraphs) do
                st.pending[paragraph.text_key] = true
                input[#input + 1] = string.format("<P%d>\n%s\n</P%d>", i, paragraph.text, i)
            end

            local body = {
                model = model,
                stream = true,
                temperature = options.temperature or conf.temperature or 0.3,
                max_tokens = options.max_tokens or conf.max_tokens or 2048,
                messages = {
                    { role = "system", content = prompt },
                    { role = "user", content = table.concat(input, "\n\n") },
                },
            }

            st.app_state.app.session[name] = body.messages

            local tmp = vim.fn.tempname()
            vim.fn.writefile({ vim.json.encode(body) }, tmp)

            local acc = {}
            local stderr_acc = {}

            local function finish_pending()
                for _, paragraph in ipairs(paragraphs) do
                    st.pending[paragraph.text_key] = nil
                end
            end

            local function handle_sse_line(line)
                if type(line) ~= "string" or line == "" then
                    return
                end

                local payload = line:match("^data:%s*(.*)$")
                if not payload or payload == "[DONE]" then
                    return
                end

                local ok, decoded = pcall(vim.json.decode, payload)
                if not ok or type(decoded) ~= "table" then
                    return
                end

                local choice = decoded.choices and decoded.choices[1]
                local delta = choice and choice.delta
                local t = delta and delta.content
                if t ~= nil and t ~= vim.NIL and t ~= "" then
                    acc[#acc + 1] = t
                end
            end

            show_thinking()

            local job = vim.fn.jobstart({
                "curl",
                "-sS",
                "--fail-with-body",
                "-m",
                tostring(options.timeout or conf.timeout or 30),
                "-N",
                "-X",
                "POST",
                "-H",
                "Content-Type: application/json",
                "-H",
                "Authorization: Bearer " .. key,
                "-d",
                "@" .. tmp,
                url,
            }, {
                stdout_buffered = false,
                stderr_buffered = false,
                on_stdout = function(_, data, _)
                    if type(data) ~= "table" then
                        return
                    end
                    for _, line in ipairs(data) do
                        handle_sse_line(line)
                    end
                end,
                on_stderr = function(_, data, _)
                    if type(data) ~= "table" then
                        return
                    end
                    for _, line in ipairs(data) do
                        if type(line) == "string" and line ~= "" then
                            stderr_acc[#stderr_acc + 1] = line
                        end
                    end
                end,
                on_exit = function(_, code, _)
                    pcall(vim.fn.delete, tmp)

                    vim.schedule(function()
                        clear_thinking()
                        st.in_flight = false
                        finish_pending()
                        if not vim.api.nvim_buf_is_valid(bufnr) or not window_translate_state[bufnr] then
                            return
                        end

                        local out = table.concat(acc, "")
                        if out == "" then
                            local msg = {
                                "WindowTranslate: empty output.",
                                "exit=" .. tostring(code),
                                "url=" .. tostring(url),
                                "model=" .. tostring(model),
                            }
                            if #stderr_acc > 0 then
                                msg[#msg + 1] = "\nstderr:\n" .. table.concat(stderr_acc, "\n")
                            end
                            vim.notify(table.concat(msg, "\n"), vim.log.levels.WARN)
                            if st.queued then
                                st.request_visible(true)
                            end
                            return
                        end

                        local rendered_count = 0
                        for i, paragraph in ipairs(paragraphs) do
                            local translation = out:match("<P" .. i .. ">%s*(.-)%s*</P" .. i .. ">")
                            if translation and translation ~= "" then
                                if translation_same_as_source(paragraph, translation) then
                                    st.translations[paragraph.text_key] = false
                                    st.rendered[paragraph.key] = true
                                else
                                    st.translations[paragraph.text_key] = translation
                                end
                                if st.translations[paragraph.text_key] and not st.rendered[paragraph.key] then
                                    render_window_translation(bufnr, options, paragraph, translation)
                                    st.rendered[paragraph.key] = true
                                end
                                rendered_count = rendered_count + 1
                            end
                        end

                        if st.queued then
                            vim.schedule(function()
                                if window_translate_state[bufnr] then
                                    st.request_visible(true)
                                end
                            end)
                        elseif rendered_count > 0 and #paragraphs >= options.max_paragraphs_per_request then
                            st.request_visible(true)
                        else
                            st.request_visible(false)
                        end
                    end)
                end,
            })

            if job <= 0 then
                clear_thinking()
                st.in_flight = false
                finish_pending()
                pcall(vim.fn.delete, tmp)
            end
        end

        st.request_visible = function(force)
            if not vim.api.nvim_buf_is_valid(bufnr) or not window_translate_state[bufnr] then
                return
            end

            local visible_top, visible_bottom = window_visible_range()
            local range_top = visible_top
            local range_bottom = visible_bottom
            if st.last_visible_top then
                if visible_top < st.last_visible_top then
                    range_top = range_top - options.prefetch_lines
                end
                if visible_bottom > st.last_visible_bottom then
                    range_bottom = range_bottom + options.prefetch_lines
                end
            end
            st.last_visible_top = visible_top
            st.last_visible_bottom = visible_bottom

            local paragraphs, top, bottom = range_paragraphs(bufnr, range_top, range_bottom)
            if #paragraphs == 0 then
                return
            end

            local batch = {}
            local seen_text = {}
            for _, paragraph in ipairs(paragraphs) do
                local translation = st.translations[paragraph.text_key]
                if translation == false then
                    st.rendered[paragraph.key] = true
                elseif translation then
                    if not st.rendered[paragraph.key] then
                        render_window_translation(bufnr, options, paragraph, translation)
                        st.rendered[paragraph.key] = true
                    end
                elseif not st.pending[paragraph.text_key] and not seen_text[paragraph.text_key] then
                    seen_text[paragraph.text_key] = true
                    batch[#batch + 1] = paragraph
                    if #batch >= options.max_paragraphs_per_request then
                        break
                    end
                end
            end

            if #batch == 0 then
                return
            end

            local scroll_delta = math.huge
            if st.last_request_top and st.last_request_bottom then
                scroll_delta = math.max(math.abs(top - st.last_request_top), math.abs(bottom - st.last_request_bottom))
            end

            if not force and #batch < options.min_new_paragraphs and scroll_delta < options.scroll_threshold then
                return
            end

            if st.in_flight then
                st.queued = true
                return
            end

            start_request(batch, top, bottom)
        end

        local function schedule_request(force)
            if not window_translate_state[bufnr] then
                return
            end

            if force then
                st.request_visible(true)
                return
            end

            if st.timer then
                pcall(st.timer.stop, st.timer)
            end

            st.timer:start(options.debounce_ms, 0, function()
                vim.schedule(function()
                    if not window_translate_state[bufnr] then
                        return
                    end
                    st.request_visible(false)
                end)
            end)
        end

        local uv = vim.uv or vim.loop
        st.timer = uv.new_timer()
        st.augroup = vim.api.nvim_create_augroup("llm_window_translate_" .. bufnr, { clear = true })

        vim.api.nvim_create_autocmd("WinScrolled", {
            group = st.augroup,
            callback = function()
                if vim.api.nvim_get_current_buf() == bufnr then
                    schedule_request(false)
                end
            end,
        })

        vim.api.nvim_create_autocmd("CursorMoved", {
            buffer = bufnr,
            group = st.augroup,
            callback = function()
                schedule_request(false)
            end,
        })

        vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
            buffer = bufnr,
            group = st.augroup,
            callback = function()
                clear_window_translate_overlay(bufnr)
            end,
        })

        schedule_request(true)
    end

    require("llm").setup({
        url = "http://172.16.9.15:8317/v1/chat/completions",
        model = "gpt-5.6-sol",
        api_type = "openai",
        timeout = 30,
        enable_trace = false,
        log_level = 1,
        fetch_key = function()
            return vim.env.CHATGPT_API_KEY or vim.env.QWEN_API_KEY or ""
        end,
        temperature = 0.3,
        max_tokens = 1024,

        app_handler = {
            WordTranslate = {
                handler = function()
                    return word_translate_stream_handler
                end,
                prompt = [[You are a translation expert. Your task is to translate all the text provided by the user into Chinese.
NOTE:
- All the text input by the user is part of the content to be translated, and you should ONLY FOCUS ON TRANSLATING THE TEXT without performing any other tasks.
- RETURN ONLY THE TRANSLATED RESULT.]],
                opts = {
                    exit_on_move = true,
                    enable_cword_context = true,
                    enter_flexible_window = false,
                },
            },
            WindowTranslate = {
                handler = function()
                    return window_translate_overlay_handler
                end,
                prompt = [[You are a translation expert. Translate the user's text into Chinese paragraph by paragraph.
NOTE:
- The user input is split into numbered paragraph tags like <P1>...</P1>.
- Translate each paragraph independently. Do not merge, summarize, reorder, or translate the whole input as one block.
- Preserve leading tabs and spaces at the beginning of each paragraph.
- Preserve the same paragraph tags in your output.
- RETURN ONLY THE TAGGED TRANSLATED RESULT.]],
                opts = {
                    debounce_ms = 500,
                    enter_flexible_window = false,
                    max_paragraphs_per_request = 6,
                    max_tokens = 2048,
                    min_new_paragraphs = 2,
                    overlay_max_width = 80,
                    prefetch_lines = 10,
                    scroll_threshold = 5,
                },
            },
        },
    })

    -- Only apply to llm.nvim buffers, do not affect global `q`.
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "llm",
        callback = function(ev)
            vim.keymap.set("n", "q", "<cmd>quit<cr>", { buffer = ev.buf, silent = true, nowait = true })
        end,
    })
end

M.llmKeys = {
    { "<leader>al", mode = "n", "<cmd>LLMSessionToggle<cr>", desc = "LLM chat" },
    { "<leader>at", mode = "n", "<cmd>LLMAppHandler WordTranslate<cr>", desc = "AI Translator" },
    { "<leader>at", mode = "x", "<cmd>LLMAppHandler WordTranslate<cr>", desc = "AI Translator" },
    { "<leader>uT", mode = "n", "<cmd>LLMAppHandler WindowTranslate<cr>", desc = "Translate Window Overlay" },
}

return M

