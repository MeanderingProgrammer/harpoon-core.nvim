# Introduction

Neovim harpoon plugin, but only the core bits.

Many thanks to [ThePrimeagen](https://github.com/ThePrimeagen), this
implementation takes many ideas from the original
[harpoon](https://github.com/ThePrimeagen/harpoon) plugin, as well
as various naming conventions for the commonly used publically exposed methods.

The idea with this version is, I like all the file marking and switch logic that's
part of `harpoon`, but am not interested in all of the TMUX / terminal stuff.

Looks like `ThePrimeagen` expresses some similar thoughts based on:
[issue-255](https://github.com/ThePrimeagen/harpoon/issues/255).

There are pretty large changes in this implementation so mapping the 2 outside
of what is available publically is not straightforward.

Perhaps in the future can add some support for storing other information at a
project level, but I am unsure if there is a nice way to do this.

# Features

* Supports running multiple different projects at the same time without
  losing any changes to your marked files.

# Limitations

* Having the same project open in multiple instances of Neovim will cause
  changes to your marked files to get clobbered.

# Install

## Lazy.nvim

```lua
{
    'MeanderingProgrammer/harpoon-core.nvim',
    dependencies = {
        'nvim-lua/plenary.nvim',
    },
    config = function()
        require('harpoon-core').setup({})
    end,
}
```
# Harpooning

This section is a copy paste from the original, with some minor changes / additions.

Here we'll explain how to wield the power of the harpoon.

## Marks

### Adding

You mark files you want to revisit later on.

Using Vim command:

```lua
:lua require('harpoon-core.mark').add_file()
```

Using keymap:

```lua
local mark = require('harpoon-core.mark')
vim.keymap.set('n', '<leader>a', mark.add_file, { desc = 'Harpoon: Add current file' })
```

### Removing

Can also be removed.

Using Vim command:

```lua
:lua require('harpoon-core.mark').rm_file()
```

Using keymap:

```lua
local mark = require('harpoon-core.mark')
vim.keymap.set('n', '<leader>r', mark.rm_file, { desc = 'Harpoon: Remove current file' })
```

## File Navigation

View all project marks.

Using Vim command:

```lua
:lua require('harpoon-core.ui').toggle_quick_menu()
```

Using keymap:

```lua
local ui = require('harpoon-core.ui')
vim.keymap.set('n', '<leader><leader>', ui.toggle_quick_menu, { desc = 'Harpoon: Toggle UI' })
```

You can go up and down the list, enter, delete or reorder. `q` and `<ESC>` exit and save the menu.

* TODO - currently they just exit the menu without saving, unless `w` is used.

You also can switch to any mark without bringing up the menu. Below examples use 3 as the target file.

Using Vim command:

```lua
:lua require('harpoon-core.ui').nav_file(3)
```

Using keymap:

```lua
local ui = require('harpoon-core.ui')
vim.keymap.set('n', '<leader>3', function() ui.nav_file(3) end, { desc = 'Harpoon: Open file 3' })
```
You can also cycle the list in both directions.

* TODO - this functionality is not yet implemented

Using Vim command:

```lua
:lua require('harpoon-core.ui').nav_next()
:lua require('harpoon-core.ui').nav_prev()
```

Using keymap:

```
TODO
```

From the quickmenu, open a file in:

* vertical split with `<ctrl-v>`
* horizontal split with `<ctrl-x>`
* new tab with `<ctrl-t>`
