# hanger.nvim

A small, dependency-free floating toolbar for Neovim, designed to be completely usable from the keyboard.

## Requirements

- Neovim 0.9+
- A Nerd Font is optional (replace or remove the default icons if you do not use one)

## Installation

With lazy.nvim:

```lua
{
  "hbahadorzadeh/hanger",
  opts = {},
}
```

With packer.nvim:

```lua
use({ "hbahadorzadeh/hanger", config = function() require("hanger").setup() end })
```

## Keyboard controls

Open the toolbar with `<leader>tb` or `:Hanger`.

| Keys | Action |
| --- | --- |
| `h`, `Left`, `Shift-Tab` | Previous item |
| `l`, `Right`, `Tab` | Next item |
| `Home` / `End` | First / last item |
| `Enter`, `Space` | Activate selected item |
| `Esc`, `q` | Close |

Focus remains inside the toolbar until an action is activated or the toolbar is closed.

## Configuration

```lua
require("hanger").setup({
  position = "top", -- or "bottom"
  border = "rounded",
  keymap = "<leader>tb", -- false disables the default mapping
  items = {
    { label = "Save", icon = "󰆓", command = "write" },
    { label = "Search", icon = "󰍉", keys = "/" },
    { label = "Format", action = function() vim.lsp.buf.format() end },
  },
})
```

Each item needs a `label` and exactly one useful action: an Ex `command`, normal-mode `keys`, or an `action` callback.

## License

GPL-3.0
