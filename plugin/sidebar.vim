if (exists('g:sidebar_loaded') && g:sidebar_loaded) || &compatible
    finish
endif
let g:sidebar_loaded = 1

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=1 SidebarSwitch call sidebar#switch(<q-args>)
command! -nargs=1 SidebarToggle call sidebar#toggle(<q-args>)
command! -nargs=1 SidebarClose call sidebar#close(<q-args>)

augroup sidebar
autocmd!
autocmd WinClosed * call sidebar#close_tab_if_no_editing_window()
augroup END

let s:save_cpo = &cpo
set cpo&vim
