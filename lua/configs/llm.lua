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
            local max_w = math.max(min_w, math.floor((ok_width and win_width or vim.o.columns) * 0.7))
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

                    if options.exit_on_move then
                        vim.api.nvim_create_autocmd("CursorMoved", {
                            group = vim.api.nvim_create_augroup("llm_word_translate_exit_on_move", { clear = true }),
                            callback = function()
                                if pop then
                                    pcall(function()
                                        pop:unmount()
                                    end)
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

    require("llm").setup({
        url = "http://172.16.9.15:8317/v1/chat/completions",
        -- model = "gpt-5.2",
        model = "qwen3-coder-plus",
        api_type = "openai",
        timeout = 30,
        enable_trace = false,
        log_level = 1,
        fetch_key = function()
            -- Prefer Qwen key when using qwen models; fall back to CHATGPT_API_KEY.
            return vim.env.QWEN_API_KEY or vim.env.CHATGPT_API_KEY or ""
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
}

return M

