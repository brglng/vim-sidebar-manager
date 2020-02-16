# vim-sidebar-manager

A sidebar manger for Vim/Neovim to mimic an IDE-like UI layout.

## TL;DR

(TODO)

## Motivation

We have a lot of plugins who open windows at your editor's side. I would call
them "sidebars". Unfortunately, those plugins do no cooperate with each other.
For example, if I have NERDTree and Tagbar installed, and configured to open
at the same side, they can open simultaneously, and we have to control each of
them individually. I think a better approach would be to "switch" them. That
is, when I switch to NERDTree, Tagbar is closed at the same time, and when I
switch to Tagbar, NERDTree is closed at the same time. As a result, it gives
you a feeling that there is always a bar at a side, which have several pages
that can be switched. That's pretty much like a usual UI layout of an IDE.
What's more, I want to use the same key for switching and toggling. I wrote a
lot of code to implement this behavior in the past years, and finally I found
I can make an abstraction layer, and that's this plugin,.

## Example

Here's an configuration example for NERDTree, Tagbar and Undotree at the left
side.

```vim
let g:NERDTreeWinPos = 'left'
let g:NERDTreeWinSize = 40
let g:NERDTreeQuitOnOpen = 0
let g:tagbar_left = 1
let g:tagbar_width = 40
let g:tagbar_autoclose = 0
let g:tagbar_autofocus = 1
let g:undotree_SetFocusWhenToggle = 1
let g:undotree_SplitWidth = 40

call sidebar#register({
  \ 'name': 'nerdtree',
  \ 'position': 'left',
  \ 'check_nr': {nr -> getwinvar(nr, '&filetype') ==# 'nerdtree'},
  \ 'open': 'NERDTree',
  \ 'close': 'NERDTreeClose'
  \})

call sidebar#register({
  \ 'name': 'tagbar',
  \ 'position': 'left',
  \ 'check_nr': {nr -> bufname(winbufnr(nr)) =~ '__Tagbar__'},
  \ 'open': 'TagbarOpen',
  \ 'close': 'TagbarClose'
  \ })

call sidebar#register({
  \ 'name': 'undotree',
  \ 'position': 'left',
  \ 'check_nr': {nr -> getwinvar(nr, '&filetype') =~ 'undotree'},
  \ 'open': 'UndotreeShow',
  \ 'close': 'UndotreeHide'
  \ })
```

Notes:

- `vim-sidebar-manager` does not actually move your windows or change your
  windows' sizes. The `position` field in the argument of `sidebar#register()`
  function is only a flag for the manager to recognize. If you want them to
  open at the same side, you have to adjust the individual plugins'
  configurations.

- The `check_nr` field must be a Funcref who takes the `winnr` as an argument
  and returns a boolean (number) to indicate whether or not the window
  corresponding to this `nr` is the kind of sidebar window that you are
  registering.

- The `open` and `close` fields can be either a string of command or a
  Funcref.

<!-- vim: ts=8 sts=4 sw=4 et cc=79
-->
