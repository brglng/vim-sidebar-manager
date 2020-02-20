if (exists('g:sidebar_loaded') && g:sidebar_loaded) || &compatible
    finish
endif
let g:sidebar_loaded = 1

let s:save_cpo = &cpo
set cpo&vim

function! s:complete_sidebar_name(arg_lead, cmd_line, cursor_pos)
    let all_names = []

    for sidebar in sidebar#get()
        let all_names += [sidebar.name]
    endfor

    for name in all_names
        if len(a:arg_lead) <= len(name) && name[:len(a:arg_lead) - 1] ==# a:arg_lead
            return [name]
        endif
    endfor

    return all_names
endfunction

function! s:complete_position(arg_lead, cmd_line, cursor_pos)
    let all_positions = ['left', 'bottom', 'top', 'right']

    for pos in all_positions
        if len(a:arg_lead) <= len(pos) && pos[:len(a:arg_lead) - 1] ==# a:arg_lead
            return [pos]
        endif
    endfor

    return all_positions
endfunction

command! -nargs=1 -complete=customlist,<SID>complete_sidebar_name SidebarSwitch call sidebar#switch(<q-args>)
command! -nargs=1 -complete=customlist,<SID>complete_sidebar_name SidebarToggle call sidebar#toggle(<q-args>)
command! -nargs=1 -complete=customlist,<SID>complete_sidebar_name SidebarClose call sidebar#close(<q-args>)
command! -nargs=1 -complete=customlist,<SID>complete_position SidebarCloseSide call sidebar#close_side(<q-args>)
command! -nargs=0 SidebarCloseAll call sidebar#close_all()

augroup sidebar
autocmd!

if get(g:, 'sidebar_close_tab_on_closing_last_buffer', 0)
    autocmd WinEnter * call sidebar#close_tab_on_closing_last_buffer()
endif

augroup END

let s:save_cpo = &cpo
set cpo&vim
