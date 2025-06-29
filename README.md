template.nvim is a neovim plugin that allows neovim users to `<action>`.

## ✨ Features

- Works with [mkrepo](https://github.com/2kabhishek/mkrepo)

## ⚡ Setup

### ⚙️ Requirements

- Latest version of `neovim`

### 💻 Installation

```lua
-- Lazy
{
    '2kabhishek/template.nvim',
    cmd = 'TemplateHello',
    -- Add your custom configs here, keep it blank for default configs (required)
    opts = {},
    -- Use this for local development
    -- dir = '~/path-to/template.nvim',
},
```

1. Add the code required for your plugin,

   - Add user configs to [config.lua](./lua/template/config.lua)
   - For adding commands and keybindngs use [commands.lua](./lua/template/commands.lua)
   - Separate plugin logic into modules under [modules](./lua/template/) dir

1. Add test code to the [tests](./tests/) directory

1. Tweak the [docs action](./.github/workflows/docs.yml) file to reflect your plugin name, commit email and username

   - Generating vimdocs needs read and write access to actions (repo settings > actions > general > workflow permissions)

### Configuration

hass.nvim can be configured using the following options:

```lua
template.setup({
    name = 'template.nvim', -- Name to be greeted, 'World' by default
})
```

### Commands

`hass.nvim` adds the following commands:

- `HassToken`: Enter Long-Lived access token.

### Keybindings

It is recommended to use:

- `<leader>hta,` for `HassTestAutomation`

> NOTE: By default there are no configured keybindings.

### Help

Run `:help template.txt` for more details.

## 🏗️ What's Next

Planning to add `<feature/module>`.

- [dots2k](https://github.com/2kabhishek/dots2k) — Dev Environment
- [nvim2k](https://github.com/2kabhishek/nvim2k) — Personalized Editor
- [sway2k](https://github.com/2kabhishek/sway2k) — Desktop Environment
- [qute2k](https://github.com/2kabhishek/qute2k) — Personalized Browser

### 🔍 More Info

- [nerdy.nvim](https://github.com/2kabhishek/nerdy.nvim) — Find nerd glyphs easily
- [tdo.nvim](https://github.com/2KAbhishek/tdo.nvim) — Fast and simple notes in Neovim
- [termim.nvim](https://github.com/2kabhishek/termim.nvim) — Neovim terminal improved
- [octohub.nvim](https://github.com/2kabhishek/octohub.nvim) — Github repos in Neovim
