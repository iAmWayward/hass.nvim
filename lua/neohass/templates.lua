local config = require('hass.config')
local curl = require('plenary.curl')

local M = {}

-- Find template boundaries around cursor
local function find_template_at_cursor()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor[1] - 1, cursor[2] -- Convert to 0-indexed
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    if not lines[row + 1] then
        return nil
    end

    local current_line = lines[row + 1]

    -- Check if cursor is inside any template pattern
    for _, pattern in ipairs(config.config.template_patterns) do
        local start_pos = 1
        while true do
            local match_start, match_end = string.find(current_line, pattern, start_pos)
            if not match_start then
                break
            end

            -- Check if cursor is within this match
            if col >= match_start - 1 and col <= match_end - 1 then
                config.debug_log('Found template at cursor: ' .. string.sub(current_line, match_start, match_end))
                return {
                    text = string.sub(current_line, match_start, match_end),
                    start_row = row,
                    end_row = row,
                    start_col = match_start - 1,
                    end_col = match_end - 1,
                }
            end
            start_pos = match_end + 1
        end
    end

    -- Look for multi-line templates (blocks starting with {% and ending with %})
    local block_start, block_end = find_template_block(lines, row)
    if block_start and block_end then
        local template_lines = {}
        for i = block_start + 1, block_end + 1 do
            table.insert(template_lines, lines[i])
        end
        return {
            text = table.concat(template_lines, '\n'),
            start_row = block_start,
            end_row = block_end,
            multiline = true,
        }
    end

    return nil
end

-- Find template block boundaries (for {% ... %} blocks)
local function find_template_block(lines, cursor_row)
    local start_row, end_row

    -- Look backwards for block start
    for i = cursor_row, 0, -1 do
        local line = lines[i + 1]
        if line and line:match('{%%.-%%}') and (line:match('if') or line:match('for') or line:match('macro')) then
            start_row = i
            break
        end
    end

    -- Look forwards for block end
    if start_row then
        for i = cursor_row + 1, #lines - 1 do
            local line = lines[i + 1]
            if line and line:match('{%%.-end.-%%}') then
                end_row = i
                break
            end
        end
    end

    return start_row, end_row
end

-- Core template rendering function
M.render_template = function(template_text)
    if not template_text or template_text == '' then
        error('No template content provided')
    end

    config.debug_log('Sending template: ' .. template_text)

    local ok, res = pcall(function()
        return curl.post(config.config.url .. '/api/template', {
            headers = config.get_headers(),
            body = vim.json.encode({ template = template_text }),
            timeout = config.config.timeout,
        })
    end)

    if not ok then
        error('Network error: ' .. tostring(res))
    end

    if res.status ~= 200 then
        local error_msg = 'HTTP ' .. res.status
        if res.body then
            local ok_json, parsed = pcall(vim.json.decode, res.body)
            if ok_json and parsed.message then
                error_msg = error_msg .. ': ' .. parsed.message
            else
                error_msg = error_msg .. ': ' .. res.body
            end
        end
        error(error_msg)
    end

    config.debug_log('Received response: ' .. res.body)
    return res.body
end

-- Render template from entire buffer
M.render_from_buffer = function(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    return M.render_template(table.concat(lines, '\n'))
end

-- Enhanced display with auto-close and better formatting
M.display_result = function(content, template_info)
    local lines = vim.split(content, '\n')
    local bufnr = vim.api.nvim_create_buf(false, true)

    -- Add header if we have template info
    if template_info then
        local header = {}
        if template_info.multiline then
            table.insert(header, '# Template Block Result')
            table.insert(header, '> Lines ' .. (template_info.start_row + 1) .. '-' .. (template_info.end_row + 1))
        else
            table.insert(header, '# Template Result')
            table.insert(header, '> ' .. template_info.text)
        end
        table.insert(header, '')

        -- Combine header with content
        local all_lines = {}
        for _, line in ipairs(header) do
            table.insert(all_lines, line)
        end
        for _, line in ipairs(lines) do
            table.insert(all_lines, line)
        end
        lines = all_lines
    end

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_set_option_value('filetype', 'markdown', { buf = bufnr })
    vim.api.nvim_set_option_value('modifiable', false, { buf = bufnr })

    local width = math.min(80, vim.api.nvim_get_option_value('columns', {}) - 4)
    local height = math.min(20, #lines + 2)

    local opts = {
        relative = 'cursor',
        width = width,
        height = height,
        row = 1,
        col = 0,
        style = 'minimal',
        border = 'rounded',
        title = ' Home Assistant Template ',
        title_pos = 'center',
    }

    local winid = vim.api.nvim_open_win(bufnr, false, opts)

    -- Auto-close after delay if configured
    if config.config.auto_close_delay then
        vim.defer_fn(function()
            if vim.api.nvim_win_is_valid(winid) then
                vim.api.nvim_win_close(winid, true)
            end
        end, config.config.auto_close_delay)
    end

    -- Set up keymaps for the floating window
    local keymaps = {
        ['q'] = function()
            vim.api.nvim_win_close(winid, true)
        end,
        ['<Esc>'] = function()
            vim.api.nvim_win_close(winid, true)
        end,
    }

    for key, func in pairs(keymaps) do
        vim.keymap.set('n', key, func, { buffer = bufnr, silent = true })
    end

    return winid
end

-- Smart template rendering (cursor → buffer fallback)
M.render_smart = function()
    local template_info = find_template_at_cursor()

    if template_info then
        -- Render template at cursor
        config.debug_log('Rendering template at cursor')
        local ok, result = pcall(M.render_template, template_info.text)
        if ok then
            M.display_result(result, template_info)
        else
            vim.notify('Template error: ' .. result, vim.log.levels.ERROR)
        end
    else
        -- Fall back to entire buffer
        config.debug_log('No template at cursor, rendering entire buffer')
        local ok, result = pcall(M.render_from_buffer, vim.api.nvim_get_current_buf())
        if ok then
            M.display_result(result)
        else
            vim.notify('Template error: ' .. result, vim.log.levels.ERROR)
        end
    end
end

-- Validate Home Assistant connection
M.validate_connection = function()
    local ok, res = pcall(function()
        return curl.get(config.config.url .. '/api/', {
            headers = config.get_headers(),
            timeout = config.config.timeout,
        })
    end)

    if ok and res.status == 200 then
        vim.notify('✓ Connected to Home Assistant', vim.log.levels.INFO)
        return true
    else
        vim.notify('✗ Failed to connect to Home Assistant', vim.log.levels.ERROR)
        return false
    end
end

-- Toggle debug mode
M.toggle_debug = function()
    config.config.debug = not config.config.debug
    vim.notify('Debug mode: ' .. (config.config.debug and 'ON' or 'OFF'))
end

return M
