if (exists('g:sidebar_loaded') && g:sidebar_loaded) || &compatible
    finish
endif
let g:sidebar_loaded = 1

let s:save_cpo = &cpo
set cpo&vim

let g:sidebar_left_width = get(g:, 'sidebar_left_width', 40)
let g:sidebar_right_width = get(g:, 'sidebar_right_width', 40)
let g:sidebar_top_height = get(g:, 'sidebar_top_height', 0.4)
let g:sidebar_bottom_height = get(g:, 'sidebar_bottom_height', 0.4)
let g:sidebar_move = get(g:, 'sidebar_move', 1)

let s:default_opts = {
\   'winfixwidth': 0,
\   'winfixheight': 0,
\   'winhighlight': 'Normal:NormalFloat',
\   'number': 0,
\   'foldcolumn': 0,
\   'signcolumn': 'no',
\   'colorcolumn': 0,
\   'bufhidden': 'hide',
\   'buflisted': 0,
\ }

if exists('g:sidebar_opts')
    let g:sidebar_opts = extend(g:sidebar_opts, s:default_opts)
else
    let g:sidebar_opts = s:default_opts
endif

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

command! -nargs=1 -complete=customlist,<SID>complete_sidebar_name SidebarOpen call sidebar#open(<q-args>)
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
    autocmd BufWinEnter,FileType * call sidebar#setup_current_sidebar_window()
augroup END

let s:save_cpo = &cpo
set cpo&vim
