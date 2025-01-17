# Neomark

A Neovim plugin for folks who love taking notes in markdown and hate to leave the terminal.

## Motivation

I have been using Obsidian for a while, however, due to some undisclosed circumstances I have lost my taste for it and I have been looking for an (ideally terminal based) alternatives that would provide an experience similar to that of Obsidians combined preview/edit mode. Tried both stand-alone tools and neovim plugins for rendering/editing markdown files even the obsidian plugin for nvim. However, none of them were even close feature-wise, or they have not been working at all (but then again, I'm terrible @ reading docs and writing configs so that could have been on me :sweat_smile:). So being as picky as I am, what choice did I have other than to write a markdown plugin of my own? :sweat_smile:

## Features

1. Rendering of markdown elements - similar to Obsidians fashion, neomark renders markdown elements for the whole buffer except the line you-re cursor is @.
    - Supported elements so far: 
        - headers: `#`, `##`, ...
        - inline formatting: bold, italic, strikethrough 
        - checkboxes: `- [ ]`/`No. [ ]`
        - links: `[Link](url)`
        - code blocks - both inline and multiline with syntax highlighting powerred by [Treesitter](https://github.com/nvim-treesitter/nvim-treesitter)

2. Interactive mode - lets you jump between interactive elements like links and checkboxes and interact with them (toggle checkboxes, open links)

3. Snippets with a pick and place telescope window to insert links and images

4. List autocompletion - automatic numbering and insertion for numberred and bullet point lists

5. Format selected text to bold/italic/strikethrough in visual mode

## Installation

Neomark piggybacks off of [Treesitter](https://github.com/nvim-treesitter/nvim-treesitter) markdown parser for link concealment and code block syntax highlighting.

So far tested only with [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    'mrbya/neomark',
    dependencies = {
        -- Treesitter with markdown parser
        'nvim-treesitter/nvim-treesitter',
        opts = {
            highlight = {
                enable = true,
            },
            ensure_installed = {
                'markdown',
            },
        },
    },
    event = 'VeryLazy',
    opts = { },
}
```
`opts` table required to load plugin (even if empty).

Alternatively you can configure Treesitter on its own then install its markdown parser using `opts` in its config or `:TSInstall markdown`

### Optional dependencies

[LuaSnip](https://github.com/L3MON4D3/LuaSnip) and [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim/tree/master) required if you want to use pick and place snippets 
```lua
{
    'mrbya/neomark',
    dependencies = {
        -- Treesitter config...
        
        -- LuaSnip & telescope.nvim
        'L3MON4D3/LuaSnip',
        'nvim-telescope/telescope.nvim'
    },

    -- rest of plugin config...
}
```

to render Images inline with text you can use [image.nvim](https://github.com/3rd/image.nvim) heres a [lazy.nvim](https://github.com/folke/lazy.nvim) config I use with kitty + tmux:
```lua
{
        '3rd/image.nvim',
        lazy = false,
        config = function ()
            require("image").setup({
              backend = "kitty",
              processor = "magick_rock",
              integrations = {
                markdown = {
                  enabled = true,
                  clear_in_insert_mode = false,
                  download_remote_images = true,
                  only_render_image_at_cursor = false,
                  floating_windows = false,
                  filetypes = { "markdown", "vimwiki" },
                },
                html = {
                  enabled = true,
                },
                css = {
                  enabled = true,
                },
              },
              max_width = nil,
              max_height = nil,
              max_width_window_percentage = 50,
              max_height_window_percentage = 75,
              window_overlap_clear_enabled = false,
              window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
              editor_only_render_when_focused = false,
              tmux_show_only_in_active_window = true,
              hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
            })
        end
    },
```

## Configuration

### Default config
```lua
{
    disable = { },

    filetypes = { '*.md' },

    keymaps = {
        interactive_mode_enter = '<leader>i',
        interactive_mode_exit = '<Esc>',
        forward = '<Right>',
        backward = '<Left>',
        up = '<Up>',
        down = '<Down>',
        interact = '<CR>',
        format_bold = '<leader>b',
        format_italic = '<leader>i',
        format_strikethrough = '<leader>s',
    },

    snippets = false,
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

### Automatic numbering/autocompletion configuration

To disable automatic list numbering and bullet point list autocompletion add the elements to be disabled to the `disable` table in your plugin `opts`.

Eg.
```lua
opts = {
    -- Disables autocomplete altogether
    disable = {
        'numberred_list',
        'bullet_point_list',
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
3. Format selection in visual mode using:

| Keymap | Command |
| -------------- | --------------- |
| `<leader>b` | Format selection to bold |
| `<leader>i` | Format selection to italic |
| `<leader>s` | Format selection to strikethrough |


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
| Format to bold | `Nmfb` |
| Format to italic | `Nmfi` |
| Format to strikethrough | `Nmfs` |

### Snippets

Pick and place snippets:

| Snippet | Trigger |
| -------------- | --------------- |
| link | `neolink` |
| image | `neoimg` |

To bring up telescope pick and place window tab out of the snippets `url` node without editing it.

## Troubleshooting

1. Check if lazy loads Neomark using `:Lazy`. If not, you have probably missed `opts` in the plugin config.
- (see [Installation](#Installation))

2. If rendering, concealment or optional features like pick and place snippets are not working there's prolly a missng/misconfigured dependency. Use `:checkhealth` to get info about installed dependencies.

3. If pick and place snippets do not trigger check your `opts` if enabled.
- (see [Snippet configuration](#Snippet-configuration))

## Upcomming features

- [x] Opening links to markdown file sections (url#header)
- [x] Checkbox snippet
- [x] Format selection in vm
- [x] Automatic numbering
- [ ] Toggle formatting
- [ ] Render tables
- [ ] Copy paste images
- [ ] plantuml?
