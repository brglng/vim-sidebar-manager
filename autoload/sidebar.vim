let s:redraw_timeout = get(g:, 'sidebar_redraw_timeout', '30m')

let s:sidebars = {}
let s:position_name_map = {'left': [], 'bottom': [], 'top': [], 'right': []}

function! sidebar#register(desc)
    let s:sidebars[a:desc.name] = a:desc
    let s:position_name_map[a:desc.position] += [a:desc.name]
endfunction

function! s:register_g_sidebars()
    for [name, attrs] in items(g:sidebars)
        let desc = copy(attrs)
        let desc['name'] = name
        call sidebar#register(desc)
    endfor
endfunction

if exists('g:sidebars')
    call s:register_g_sidebars()
endif

function! s:call_or_exec(func_or_cmd)
    if type(a:func_or_cmd) is v:t_func
        call call(a:func_or_cmd, [])
    else
        call execute(a:func_or_cmd)
    endif
endfunction

function! s:redraw_and_sleep()
    redraw
    execute 'sleep ' . s:redraw_timeout
endfunction

function! s:find_windows_at_position(position)
    let found_nr_name_map = {}
    for i in range(1, winnr('$'))
        for name in s:position_name_map[a:position]
            if call(s:sidebars[name].check_win, [i])
                let found_nr_name_map[i] = name
            endif
        endfor
    endfor
    return found_nr_name_map
endfunction

function! s:win_save_view()
    let w:__sidebar_view__ = winsaveview()
endfunction

function! s:win_restore_view()
    if exists('w:__sidebar_view__')
        call winrestview(w:__sidebar_view__)
        unlet w:__sidebar_view__
    endif
endfunction

function! s:save_view()
    noautocmd windo call <SID>win_save_view()
endfunction

function! s:restore_view()
    noautocmd windo call <SID>win_restore_view()
endfunction

function! sidebar#switch(name)
    call s:save_view()
    let found_desired_nr = 0
    let found_wins = s:find_windows_at_position(s:sidebars[a:name].position)
    for [found_nr, found_name] in items(found_wins)
        if found_name ==# a:name
            let found_desired_nr = found_nr
        else
            call s:call_or_exec(s:sidebars[found_name].close)
        endif
    endfor

    call s:redraw_and_sleep()

    if found_desired_nr > 0
        execute found_desired_nr . 'wincmd w'
    else
        call s:call_or_exec(s:sidebars[a:name].open)
    endif
    call s:restore_view()
endfunction

function! sidebar#close(name)
    call s:save_view()
    let nr = 0
    for i in range(1, winnr('$'))
        if call(s:sidebars[a:name].check_win, [i])
            call s:call_or_exec(s:sidebars[a:name].close, [])
        endif
    endfor
    call s:restore_view()
endfunction

function! sidebar#toggle(name)
    call s:save_view()
    let found_desired_nr = 0
    let found_wins = s:find_windows_at_position(s:sidebars[a:name].position)
    for [found_nr, found_name] in items(found_wins)
        if found_name ==# a:name
            let found_desired_nr = found_nr
        else
            call s:call_or_exec(s:sidebars[found_name].close)
        endif
    endfor

    call s:redraw_and_sleep()

    if found_desired_nr > 0
        call s:call_or_exec(s:sidebars[a:name].close)
    else
        call s:call_or_exec(s:sidebars[a:name].open)
    endif
    call s:restore_view()
endfunction

function! sidebar#close_side(position)
    call s:save_view()
    for name in s:position_name_map[a:position]
        call call(s:sidebars[name].close, [])
    endfor
    call s:restore_view()
    redraw
endfunction

function! sidebar#close_all()
    call s:save_view()
    for [name, desc] in items(s:sidebars)
        call call(desc.close, [])
    endfor
    call s:restore_view()
    redraw
endfunction

function! s:is_sidebar(nr)
    for [name, desc] in items(s:sidebars)
        if call(desc.check_win, [a:nr])
            return v:true
        endif
    endfor
    return v:false
endfunction

function! sidebar#close_tab_if_no_editing_window()
    if get(g:, 'sidebar_close_tab_if_no_editing_window', 0)
        let num_editing_wins = 0
        for i in range(1, winnr('$'))
            if !s:is_sidebar(i)
                let num_editing_wins += 1
            endif
        endfor

        if num_editing_wins == 1
            try
                confirm tabclose
            catch /E784:/
                confirm qall
            endtry
        endif
    endif
endfunction
