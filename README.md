# Introduction

Neovim harpoon plugin, but only the core bits.

Many thanks to [ThePrimeagen](https://github.com/ThePrimeagen), this
implementation takes many ideas from the original
[harpoon](https://github.com/ThePrimeagen/harpoon) plugin, as well as
various naming conventions for the commonly used publicly exposed methods.

The idea is I like all the file marking and switch logic that's part of `harpoon`,
but am not interested in all of the TMUX / terminal stuff.

Looks like `ThePrimeagen` expresses some similar thoughts based on:
[issue-255](https://github.com/ThePrimeagen/harpoon/issues/255).

There are pretty large changes in this implementation so mapping the 2 outside
of what is available publicly is not straightforward.

# Features

- Supports running multiple different projects at the same time without losing any
  changes to your marked files.
- Invalid marks get filtered out, only valid changes propagate to marks.
- Marking files at a branch granularity if `mark_branch` option is set.
- Will set active window to specified file if it is already open rather than
  opening another window if `use_existing` option is set, works across tabs.
- Supports storing and using last cursor position if `use_cursor` option is set.
- Supports different default actions when opening a mark with `default_action` option.
- A migration script to move existing harpoon marks over.

# Limitations

- Having the same project open in multiple instances of Neovim will cause
  changes to your marked files to get clobbered.

# Differences from Original

While many of the publicly exposed behaviors have been copied to be nearly exact
there are a couple of intentional differences in behavior:

- Invalid files are never saved to your marks. When editing you can add whatever
  lines you want to the preview, but if it doesn't point to an actual file it'll
  be thrown out immediately and never persisted. This will also happen if you later
  delete a file after the first time you open the preview window.
- As a consequence of the above empty lines are also not allowed. Though there may
  be some value in having your shortcuts remain consistent even when some file is
  removed this implementation avoids having placeholder slots that need special handling.
- Minor other changes and bug fixes such as [218](https://github.com/ThePrimeagen/harpoon/pull/218).

# Install

## lazy.nvim

```lua
{
    'MeanderingProgrammer/harpoon-core.nvim',
    config = function()
        require('harpoon-core').setup({})
    end,
}
```

# Setup

Below is the configuration that gets used by default, any part of it can be modified
by the user.

```lua
require('harpoon-core').setup({
    -- Set marks specific to each git branch inside git repository
    mark_branch = false,
    -- Make existing window active rather than creating a new window
    use_existing = true,
    -- Default action when opening a mark, defaults to current window
    -- Example: 'vs' will open in new vertical split, 'tabnew' will open in new tab
    default_action = nil,
    -- Use the previous cursor position of marked files when opened
    use_cursor = true,
    -- Settings for popup window
    menu = { width = 60, height = 10 },
    -- Controls confirmation when deleting mark in telescope
    delete_confirmation = true,
    -- Controls keymaps for various telescope actions
    picker = {
        delete = '<c-d>',
        move_down = '<c-n>',
        move_up = '<c-p>',
    },
})
```

# Migrate Harpoon Marks

This can be done by executing the import_harpoon script: `python3 scripts/import_harpoon.py`

This requires `python` to be installed but does not rely on any additional libraries.

# Harpooning

This section is a copy paste from the original, with some minor changes / additions.

You can see an example config which assigns all of these commands to keymaps
[here](https://github.com/MeanderingProgrammer/dotfiles/blob/main/.config/nvim/lua/mp/plugins/harpoon.lua).

Here we'll explain how to wield the power of the harpoon.

## Marks

### Adding

You mark files you want to revisit later on.

```lua
:lua require('harpoon-core').add_file()
```

### Removing

These can also be removed.

```lua
:lua require('harpoon-core').rm_file()
```

## File Navigation

View all project marks.

```lua
:lua require('harpoon-core').toggle_quick_menu()
```

You can go up and down the list, enter, delete or reorder. `q` and `<esc>` exit
and save the menu.

You can also switch to any mark without bringing up the menu. Below example uses
3 as the target file.

```lua
:lua require('harpoon-core').nav_file(3)
```

You can also cycle the list in both directions.

```lua
:lua require('harpoon-core').nav_next()
:lua require('harpoon-core').nav_prev()
```

From the quickmenu, open a file with:

- `<c-v>` vertical split
- `<c-x>` horizontal split
- `<c-t>` new tab

# Telescope Support

First register harpoon as a telescope extension.

```lua
require('telescope').load_extension('harpoon-core')
```

Then open the marks page.

```vim
:Telescope harpoon-core marks
```

Valid keymaps in Telescope are:

- `<c-d>` delete the current mark
- `<c-p>` move mark up one position
- `<c-n>` move mark down one position

You can override these keymaps in your config:

```lua
require('harpoon-core').setup({
    picker = {
        delete = '<C-x>',
        move_down = '<C-S-j>',
        move_up = '<C-S-k>',
    },
})
```
