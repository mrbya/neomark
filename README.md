# Neomark

A plugin for folks who love taking notes in markdown and hate to leave the terminal.

## Motivation

I have been using Obsidian for a while, however, due to some undisclosed circumstances I have lost my taste for it and I have been looking for an (idally terminal based) alternatives that would provide an experience similar to that of Obsidians combined preview/edit mode. Tried both stand-alone tools and neovim plugins for rendering/editing markdown files even the obsidian plugin for nvim. All of them were not even close feature-wise or they have not been working at all (but then again, I'm terrible @ reading docs and writing configs so that could have been on me :sweat_smile:). So being as picky as I am, what choice did I have other than to write a markdown plugin of my own? :sweat_smile:

## Features

1. Rendering of markdown elements - similar to Obsidians fashion, neomark renders markdown elements for the whole buffer except the line you-re cursor is @.
    - Supported elements so far: 
        - headers: `#`, `##`, ...
        - inline formatting: bold, italic, strikethrough 
        - checkboxes: `- [ ]`/`#. [ ]`
        - links: `[Paceholder](link)`
        - code blockx - both inline and multiline

2. Interactive mode - lets you jump between interactive elements like links and checkboxes and interact with them (toggle checkboxes, open links)

## Installation

So far tested only with [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    'mrbya/neomark',
    event = 'VeryLazy',
    opts = { },
},
```
`opts` table required to load plugin (even if empty).

## Configuration

### Default config
```lua
{
    disable = {},

    filetypes = { '*.md' },

    keymaps = {
        interactive_mode = '<leader>i',
        forward = '<Right>',
        backward = '<Left>',
        up = '<Up>',
        Down = '<Down>'
        interact = '<CR>',
    },
}
```

### Rendering configuration

To disable rendering of a specific element provide a `disable` table in `opts`.

Eg.
```lua
opts = {
    disable = {
        'h1',
        'inline',
    },
}
```

### Keymap configuration

To configure keymaps proivde the keymaps for specific actions in a `keymaps` table in `opts`.

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

## Usage

1. Rendering starts on opening a markdown file in a buffer.
2. Use `<leader>i` to enter interactive mode:
    - Use arrow keys to navigate between interactive elements
    - Use `<CR>` to interact with an element
3. Profit

## Upcomming features

1. Pick and place links to markdown files inside a workspace
2. Tables
3. Code blocks syntax highlighting
