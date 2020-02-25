# vim-sidebar-manager

A sidebar manger for Vim/Neovim to mimic an IDE-like UI layout.

## TL;DR

![Screencast](https://github.com/brglng/images/raw/master/vim-sidebar-manager/screencast.webp)

## Motivation

We have a lot of plugins who open windows at your editor's side. I would call
them "sidebars". Unfortunately, those plugins do no cooperate with each other.
For example, if you have NERDTree and Tagbar installed, and configured to open
at the same side, they can open simultaneously, and you have to control each
of them individually. I think a better approach would be to "switch" them.
That is, when you switch to NERDTree, Tagbar is closed automatically, and when
you switch to Tagbar, NERDTree is closed automatically. As a result, it gives
you a feeling that there is always a bar at a side, where there are several
pages that can be switched back and forth. That's pretty much like a typical
UI layout of an IDE.  What's more, I want to use the same key for switching
and toggling. I wrote a lot of code to implement this behavior in the past
years, and finally noticed that an abstraction layer can be made, and that's
this plugin.

## Example

Here's an example of configuration for NERDTree, Tagbar and Undotree at the
left side.

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

let g:sidebars = {
  \ 'nerdtree': {
  \     'position': 'left',
  \     'check_win': {nr -> getwinvar(nr, '&filetype') ==# 'nerdtree'},
  \     'open': 'NERDTree',
  \     'close': 'NERDTreeClose'
  \ },
  \ 'tagbar': {
  \     'position': 'left',
  \     'check_win': {nr -> bufname(winbufnr(nr)) =~ '__Tagbar__'},
  \     'open': 'TagbarOpen',
  \     'close': 'TagbarClose'
  \ },
  \ 'undotree': {
  \     'position': 'left',
  \     'check_win': {nr -> getwinvar(nr, '&filetype') ==# 'undotree'},
  \     'open': 'UndotreeShow',
  \     'close': 'UndotreeHide'
  \ }
  \ }

noremap <silent> <M-1> :call sidebar#toggle('nerdtree')<CR>
noremap <silent> <M-2> :call sidebar#toggle('tagbar')<CR>
noremap <silent> <M-3> :call sidebar#toggle('undotree')<CR>

let g:startify_session_before_save = ['call sidebar#close_all()']
```

Notes:

- `vim-sidebar-manager` _does not_ actually move your windows or change your
  windows' sizes. The `position` field in each sidebar description is only a
  flag for recognition. If you want them to open at the same side, you have to
  adjust the individual plugins' configurations.

- The `check_win` field must be a Funcref who takes the `winnr` as an argument
  and returns a boolean (number) to indicate whether or not the window
  corresponding to this `nr` is the specific kind of sidebar window .

- The `open` and `close` fields can be either a string of command or a
  Funcref.

For more examples, please refer to the [Wiki page](https://github.com/brglng/vim-sidebar-manager/wiki/Examples)

<!-- vim: ts=8 sts=4 sw=4 et cc=79
-->
