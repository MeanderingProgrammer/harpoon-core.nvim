# Introduction

Neovim harpoon like plugin, but only the core bits.

I like all the file marking and switch logic that's part of
[harpoon](https://github.com/ThePrimeagen/harpoon), but am not particularly
interested in all of the TMUX / terminal stuff.

Creating a sort of fork with some heavy modifications to get this done.

Looks like ThePrimeagen expresses some similar thoughts based on:
[issue-255](https://github.com/ThePrimeagen/harpoon/issues/255).

# Features

* Supports running multiple different projects at the same time without
  losing any changes to your marked files.

# Limitations

* Having the same project open in multiple instances of Neovim will cause
  changes to your marked files to get clobbered.
