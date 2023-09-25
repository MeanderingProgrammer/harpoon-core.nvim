# Introduction

Neovim harpoon like plugin, but only the core bits.

I like all the file marking and switch logic that's part of
[harpoon](https://github.com/ThePrimeagen/harpoon), but am not particularly
interested in all of the TMUX / terminal stuff.

Creating a sort of fork with some heavy modifications to get this done.

Looks like ThePrimeagen expresses some similar thoughts based on:
[issue-255](https://github.com/ThePrimeagen/harpoon/issues/255).

# TODO

* Based on how we handle deleting and moving files `add_file` method may
  need to have first available index logic, as opposed to always appending
  to the end of the table.
