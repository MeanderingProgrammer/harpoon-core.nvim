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
* Invalid marks get filtered out, only valid changes propagate to marks.
* Marking files at a branch granularity if `mark_branch` option is set.
* Will set active window to specified file if it is already open rather than
  opening another window if `use_existing` option is set, works across tabs.

# Limitations

* Having the same project open in multiple instances of Neovim will cause
  changes to your marked files to get clobbered.

# Differences from Original

While many of the publically exposed behaviors have been copied to be nearly exact there
are a couple of intentional differences in behavior:

* Invalid files are never saved to your marks. When editing you can add whatever
  lines you want to the preview, but if it doesn't point to an actual file it'll
  be thrown out immediately and never persisted. This will also happen if you later
  delete a file after the first time you open the preview window.
* As a consequence of the above empty lines are also not allowed. Though there may be
  some value in having your shortcuts remain consistent even when some file is removed
  this implementation avoids having placeholder slots that need special handling.

# Install

## Lazy.nvim

```lua
{
    'MeanderingProgrammer/harpoon-core.nvim',
    dependencies = {
        'nvim-lua/plenary.nvim',
    },
    config = function()
        require('harpoon-core').setup({
            -- Make existing window active rather than creating a new window
            use_existing = true,
            -- Set marks specific to each git branch inside git repository
            mark_branch = false,
            -- Settings for popup window
            menu = {
                width = 60,
                height = 10,
            },
            -- Highlight groups to use for various components
            highlight_groups = {
                window = 'HarpoonWindow',
                border = 'HarpoonBorder',
            },
        })
    end,
}
```
# Harpooning

This section is a copy paste from the original, with some minor changes / additions.

You can see an example config which assigns all of these commands to keymaps
[here](https://github.com/MeanderingProgrammer/dotfiles/blob/main/.config/nvim/lua/plugins/harpooncore.lua).

Here we'll explain how to wield the power of the harpoon.

## Marks

### Adding

You mark files you want to revisit later on.

```lua
:lua require('harpoon-core.mark').add_file()
```

### Removing

These can also be removed.

```lua
:lua require('harpoon-core.mark').rm_file()
```

## File Navigation

View all project marks.

```lua
:lua require('harpoon-core.ui').toggle_quick_menu()
```

You can go up and down the list, enter, delete or reorder. `q` and `<ESC>` exit and save the menu.

You can also switch to any mark without bringing up the menu. Below example uses 3 as the target file.

```lua
:lua require('harpoon-core.ui').nav_file(3)
```

You can also cycle the list in both directions.

```lua
:lua require('harpoon-core.ui').nav_next()
:lua require('harpoon-core.ui').nav_prev()
```

From the quickmenu, open a file in:

* vertical split with `<ctrl-v>`
* horizontal split with `<ctrl-x>`
* new tab with `<ctrl-t>`
