local M = {}
local curl = require('plenary.curl')

vim.g.homeassistant = M

-- Render a template using the hass template api
M.template = function(lines)
    local res = curl.post(M.url .. '/api/template', {
        headers = M.headers(),
        body = vim.json.encode({ template = table.concat(lines, '\n') }),
    })
    if res.status ~= 200 then
        error(res.body)
    end
    return res.body
end

-- Return /api/templates from buffer
M.template_from_buffer = function(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    return M.template(lines)
end

-- Display result in a floating window if the template func succeeded
M.display_result = function(lines)
    local content = vim.split(lines, '\n')
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, content)
    vim.api.nvim_set_option_value('filetype', 'markdown', { buf = bufnr })

    local opts = {
        relative = 'cursor',
        width = math.min(60, vim.api.nvim_get_option_value('columns', {}) - 4),
        height = math.min(60, #content),
        row = 1,
        col = 0,
        style = 'minimal',
        border = 'rounded',
    }

    vim.api.nvim_open_win(bufnr, false, opts)
end

-- register new commands (and other stuff probably)
local function on_setup()
    -- HARender
    vim.api.nvim_create_user_command('HARender', function(_)
        return M.display_result(M.template_from_buffer(vim.api.nvim_get_current_buf()))
    end, {
        nargs = 0,
        bang = true, -- force redefinition
    })
end

-- Initialize the plugin with user url and token
M.setup = function(opts)
    vim.validate({
        url = { opts.url, 'string' },
        token = { opts.token, 'string' },
    })

    M.url = opts.url

    -- Provides auth headers
    -- Wrap the headers in a function to not expose the token easily
    M.headers = function()
        return {
            ['Authorization'] = 'Bearer ' .. opts.token,
            ['Content-Type'] = 'application/json',
        }
    end
    on_setup()
end

return M
