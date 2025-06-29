local template = require('hass.template')
local config = require('hass.config').config

local M = {}

M.setup = function()
    -- Main command with smart rendering and subcommands
    vim.api.nvim_create_user_command('HARender', function(opts)
        if opts.args == 'test' then
            template.validate_connection()
        elseif opts.args == 'debug' then
            template.toggle_debug()
        else
            template.render_smart()
        end
    end, {
        nargs = '?',
        bang = true,
        complete = function()
            return { 'test', 'debug' }
        end,
        desc = 'Render Home Assistant template (smart detection). Use "test" to validate connection, "debug" to toggle debug mode.',
    })

    -- Force render entire buffer
    vim.api.nvim_create_user_command('HARenderBuffer', function(_)
        local ok, result = pcall(template.render_from_buffer, vim.api.nvim_get_current_buf())
        if ok then
            template.display_result(result)
        else
            vim.notify('Template error: ' .. result, vim.log.levels.ERROR)
        end
    end, {
        nargs = 0,
        bang = true,
        desc = 'Render entire buffer as Home Assistant template (ignore cursor position)',
    })

    -- Connection test command
    vim.api.nvim_create_user_command('HATest', function(_)
        template.validate_connection()
    end, {
        nargs = 0,
        desc = 'Test connection to Home Assistant',
    })

    -- Debug toggle command
    vim.api.nvim_create_user_command('HADebug', function(_)
        template.toggle_debug()
    end, {
        nargs = 0,
        desc = 'Toggle Home Assistant debug mode',
    })

    -- Add default keybindings if enabled
    if config.add_default_keybindings then
        local function add_keymap(keys, cmd, desc)
            vim.keymap.set('n', keys, cmd, { noremap = true, silent = true, desc = desc })
        end

        -- Main keybindings
        add_keymap('<leader>hr', ':HARender<CR>', 'Home Assistant: Render template (smart)')
        add_keymap('<leader>hb', ':HARenderBuffer<CR>', 'Home Assistant: Render buffer')
        add_keymap('<leader>ht', ':HATest<CR>', 'Home Assistant: Test connection')
        add_keymap('<leader>hd', ':HADebug<CR>', 'Home Assistant: Toggle debug')

        -- Quick access for common actions
        add_keymap('<leader>h<CR>', ':HARender<CR>', 'Home Assistant: Quick render')
    end
end

return M
