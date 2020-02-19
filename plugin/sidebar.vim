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

if get(g:, 'sidebar_close_tab_on_closing_last_buffer', 0)
    autocmd WinEnter * call sidebar#close_tab_on_closing_last_buffer()
endif

augroup END

let s:save_cpo = &cpo
set cpo&vim
