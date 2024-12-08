# Neomark

A Neovim plugin for folks who love taking notes in markdown and hate to leave the terminal.

## Motivation

I have been using Obsidian for a while, however, due to some undisclosed circumstances I have lost my taste for it and I have been looking for an (idally terminal based) alternatives that would provide an experience similar to that of Obsidians combined preview/edit mode. Tried both stand-alone tools and neovim plugins for rendering/editing markdown files even the obsidian plugin for nvim. All of them were not even close feature-wise or they have not been working at all (but then again, I'm terrible @ reading docs and writing configs so that could have been on me :sweat_smile:). So being as picky as I am, what choice did I have other than to write a markdown plugin of my own? :sweat_smile:

## Features

1. Rendering of markdown elements - similar to Obsidians fashion, neomark renders markdown elements for the whole buffer except the line you-re cursor is @.
    - Supported elements so far: 
        - headers: `#`, `##`, ...
        - inline formatting: bold, italic, strikethrough 
        - checkboxes: `- [ ]`/`#. [ ]`
        - links: `[Link](url)`
        - code blockx - both inline and multiline

2. Interactive mode - lets you jump between interactive elements like links and checkboxes and interact with them (toggle checkboxes, open links)

3. Snippets with a pick and place telescope window to insert links

## Installation

Neomark piggybacks off of [Treesitter](https://github.com/nvim-treesitter/nvim-treesitter) markdown parser for link concealment and code block syntax highlighting.

So far tested only with [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    'mrbya/neomark',
    event = 'VeryLazy',
    dependencies = {
        -- Install Treesitter markdown parser or configure
        'nvim-treesitter/nvim-treesitter',
        opts = {
            ensure_installed = {
                'markdown',
            },
        },
    },
    opts = { },
}
```
`opts` table required to load plugin (even if empty).

Optionally you can configure Treesitter on its own then install its markdown parser using `opts` or `:TSInstall markdown`

### Optional dependencies

[L3MON4D3/LuaSnip](https://github.com/L3MON4D3/LuaSnip) and [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim/tree/master) required if you want to use pick and place snippets 
```lua
{
    'mrbya/neomark',
    dependencies = {
        -- Treesitter config

        'L3MON4D3/LuaSnip',
        'nvim-telescope/telescope.nvim'
    },

    -- rest of plugin config
}
```


## Configuration

### Default config
```lua
{
    disable = {},

    filetypes = { '*.md' },

    keymaps = {
        interactive_mode_enter = '<leader>i',
        interactive_mode_exit = '<Esc>',
        forward = '<Right>',
        backward = '<Left>',
        up = '<Up>',
        Down = '<Down>'
        interact = '<CR>',
    },

    snippets = true,
}
```

### Rendering configuration

To disable rendering of a specific element provide a `disable` table in your plugin config `opts`.

Eg.
```lua
opts = {
    -- Disables H1 headers and inline formatting
    disable = {
        'h1',
        'inline',
    },
}
```

### Keymap configuration

To configure keymaps proivde the keymaps for specific actions in a `keymaps` table in your plugin config `opts`.

Eg.
```lua
opts = {
    keymaps = {
        interactive_mode = '<leader>l',
        forward = 'l',
        backward = 'h',
    },
}
```

### Snippet configuration

To enable/disable pick and place snippets set up a `snippets` switch in `opts`.

Eg.
```lua
opts = {
    -- Enables pick and place snippets
    snippets = true,
}
```

## Usage

### Keymaps

1. Rendering starts on opening a markdown file in a buffer.
2. Use `<leader>i` to enter interactive mode:
    - Use arrow keys to navigate between interactive elements
    - Use `<CR>` to interact with an element

### Commands

Same features can be acccessed using commands:

| Action | Command |
| ------------- | -------------- |
| Enter interactive mode | `Nmie` |
| Exit interactive mode | `Nmix` |
| Navigate forward | `Nmif` |
| Navigate backward | `Nmib` |
| Navigate up | `Nmiu` |
| Navigate down | `Nmid` |
| Interact | `Nnii` |

### Snippets

Pick and place snippets:

| Snippet | Trigger |
| -------------- | --------------- |
| link | `neolink` |
| image | `neoimg` |

To bring up telescope pick and place window tab out of the snippets `url` node without editing it.

### Troubleshooting

1. Check if lazy loads Neomark using `:Lazy`. If not, you have probably missed `opts` in the plugin config.
(see [Installation](#Installation))

2. If rendering, concealment or optional features like pick and place snippets are not working there's prolly a missng/misconfigured dependency. Use `:checkhealth` to get info about installed dependencies.

3. If pick and place snippets do not trigger check your `opts` if enabled.
(see [Snippets configuration](#Snippet-configuration))

## Upcomming features

1. Rendering tables
2. Maybe image rendering (no idea how to implenet it yet tho :sweat_smile:)
