# Introduction

Neovim harpoon like plugin, but only the core bits.

I like all the file marking and switch logic that's part of
[harpoon](https://github.com/ThePrimeagen/harpoon), but am not particularly
interested in all of the TMUX / terminal stuff.

Creating a sort of fork with some heavy modifications to get this done.

Looks like ThePrimeagen expresses some similar thoughts based on:
[issue-255](https://github.com/ThePrimeagen/harpoon/issues/255).

# TODO

* Figure out how we want to handle multiple neovim instances running at once
  and setting bookmarks. Currently the `save` logic is simple and dumps the
  entire contents to a file on any changes. This is based on a local state
  which does not periodically read from the file. ThePrimeagen solution is to
  only update at a project level, which seems like it would cover most cases
  and be simple enough to implement.
