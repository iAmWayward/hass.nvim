-- Define config structure here, setup function will override defaults with user config
---@class HassConfig
local M = {}

---@class HassConfigOptions
---@field url string Home Assistant URL (required)
---@field token string Home Assistant Long-Lived Access Token (required)
---@field timeout number Request timeout in milliseconds. Default: 5000
---@field auto_close_delay number? Auto-close floating window delay in ms. Default: nil (manual close)
---@field debug boolean Enable debug logging. Default: false
---@field add_default_keybindings boolean Whether to add default keybindings. Default: true
---@field template_patterns table<string> Jinja2 template patterns to detect. Default: { '{{.-}}', '{%.-%%}', '{#.-#}' }

local config = {
    url = nil, -- Required
    token = nil, -- Required
    timeout = 5000,
    auto_close_delay = nil,
    debug = false,
    add_default_keybindings = true,
    template_patterns = {
        '{{.-}}', -- {{ ... }}
        '{%.-%%}', -- {% ... %}
        '{#.-#}', -- {# ... #} (comments)
    },
}

---@type HassConfigOptions
M.config = config

---@param args HassConfigOptions?
M.setup = function(args)
    args = args or {}

    -- Validate required fields
    vim.validate({
        url = { args.url, 'string' },
        token = { args.token, 'string' },
        timeout = { args.timeout, 'number', true },
        auto_close_delay = { args.auto_close_delay, 'number', true },
        debug = { args.debug, 'boolean', true },
        add_default_keybindings = { args.add_default_keybindings, 'boolean', true },
        template_patterns = { args.template_patterns, 'table', true },
    })

    M.config = vim.tbl_deep_extend('force', M.config, args)

    -- Set up global reference for convenience
    vim.g.homeassistant = M.config

    if M.config.debug then
        print('[HomeAssistant] Plugin configured with URL: ' .. M.config.url)
    end
end

-- Optional: for submodules to force extend config after setup
function M.extend(opts)
    M.config = vim.tbl_deep_extend('force', M.config, opts or {})
end

-- Helper function to get headers with auth
function M.get_headers()
    return {
        ['Authorization'] = 'Bearer ' .. M.config.token,
        ['Content-Type'] = 'application/json',
    }
end

-- Debug logging helper
function M.debug_log(msg)
    if M.config.debug then
        print('[HomeAssistant] ' .. msg)
    end
end

return M
