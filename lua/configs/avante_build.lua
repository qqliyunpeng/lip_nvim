local M = {}

local AVANTE_LIBS_REPO = "https://gitee.com/nvim_lip/avante-libs.git"

local function notify(message, level)
    vim.schedule(function()
        vim.notify(message, level or vim.log.levels.INFO)
    end)
end

function M.build(plugin)
    local plugin_dir = plugin.dir
        or vim.fn.expand("~/.local/share/nvim/lazy/avante.nvim")

    local script = [[
set -e

plugin_dir="$1"
libs_repo="$2"

cd "$plugin_dir"
mkdir -p build
git fetch --tags origin >/dev/null 2>&1 || true

latest_tag="$(git describe --tags --abbrev=0 2>/dev/null || true)"
built_tag="$(cat build/.tag 2>/dev/null || true)"

if [ -z "$latest_tag" ]; then
    echo "No avante.nvim tag found, falling back to upstream build."
    make
    exit $?
fi

if [ "$latest_tag" = "$built_tag" ]; then
    echo "Local avante-lib is up to date: $latest_tag"
    exit 0
fi

case "$(uname -s)" in
    Linux*) platform="linux"; lib_ext="so" ;;
    Darwin*) platform="darwin"; lib_ext="dylib" ;;
    *) echo "Unsupported platform: $(uname -s)" >&2; exit 1 ;;
esac

case "$(uname -m)" in
    x86_64) arch="x86_64" ;;
    aarch64|arm64) arch="aarch64" ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

lua_version="${LUA_VERSION:-luajit}"
artifact_pattern="avante_lib-$platform-$arch-$lua_version"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

echo "Downloading avante-lib $latest_tag from $libs_repo"
git clone --depth 1 --branch "$latest_tag" "$libs_repo" "$tmp_dir"

archive="$(find "$tmp_dir" -type f \( -name "*$artifact_pattern*.tar.gz" -o -name "*$artifact_pattern*.tgz" \) | head -n 1)"
zip_archive="$(find "$tmp_dir" -type f -name "*$artifact_pattern*.zip" | head -n 1)"

if [ -n "$archive" ]; then
    tar -xzf "$archive" -C build
elif [ -n "$zip_archive" ]; then
    unzip -o "$zip_archive" -d build
else
    copied=0
    while IFS= read -r file; do
        name="$(basename "$file")"
        case "$name" in
            libavante_*."$lib_ext") name="${name#lib}" ;;
        esac
        cp "$file" "build/$name"
        copied=1
    done < <(find "$tmp_dir" -type f -name "*.$lib_ext")

    if [ "$copied" -eq 0 ]; then
        echo "No matching avante-lib artifact found for $artifact_pattern in $libs_repo@$latest_tag" >&2
        exit 1
    fi
fi

echo "$latest_tag" > build/.tag
echo "avante-lib $latest_tag installed."
]]

    local output = vim.fn.systemlist({ "bash", "-c", script, "avante-build", plugin_dir, AVANTE_LIBS_REPO })
    local message = table.concat(output, "\n")

    if vim.v.shell_error ~= 0 then
        notify(message, vim.log.levels.ERROR)
        error(message)
    elseif message ~= "" then
        notify(message, vim.log.levels.INFO)
    end
end

return M
