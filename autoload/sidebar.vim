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
    if exists('v:t_func') && type(a:func_or_cmd) is v:t_func
        noautocmd call call(a:func_or_cmd, [])
    else
        noautocmd execute a:func_or_cmd
    endif
endfunction

function! s:get_win(name)
    if has_key(s:sidebars[a:name], 'get_win')
        return call(s:sidebars[a:name].get_win, [])
    else
        for i in range(1, winnr('$'))
            if call(s:sidebars[a:name].check_win, [i])
                return i
            endif
        endfor
    endif
    return 0
endfunction

function! s:open(name)
    if s:get_win(name) == 0
        call s:call_or_exec(s:sidebars[a:name].open)
    endif
endfunction

function! s:close(name)
    if s:get_win(name) > 0
        call s:call_or_exec(s:sidebars[a:name].close)
    endif
endfunction

function! s:position(name)
    return s:sidebars[a:name].position
endfunction

function! s:find_windows_at_position(position)
    let found_nr_name_map = {}
    for name in s:position_name_map[a:position]
        let win = s:get_win(name)
        if win > 0
            let found_nr_name_map[win] = name
        endif
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
    let position = s:sidebars[a:name].position

    if index(['top', 'bottom'], position) >= 0
        call s:save_view()
    endif

    call s:open(a:name)

    if index(['top', 'bottom'], position) >= 0
        call s:restore_view()
    endif
endfunction

function! sidebar#close(name)
    let position = s:sidebars[a:name].position

    if index(['top', 'bottom'], position) >= 0
        call s:save_view()
    endif

    if has_key(a:name, 'get_win')
        if call(s:sidebars[a:name].get_win, []) > 0
            call s:close(a:name)
        endif
    else
        let nr = 0
        for i in range(1, winnr('$'))
            if call(s:sidebars[a:name].check_win, [i])
                call s:close(a:name)
            endif
        endfor
    endif

    if index(['top', 'bottom'], position) >= 0
        call s:restore_view()
    endif
endfunction

function! sidebar#toggle(name)
    let position = s:sidebars[a:name].position

    if index(['top', 'bottom'], position) >= 0
        call s:save_view()
    endif

    let found_desired_nr = 0
    let found_wins = s:find_windows_at_position(s:sidebars[a:name].position)
    for [found_nr, found_name] in items(found_wins)
        if found_name ==# a:name
            let found_desired_nr = found_nr
        endif
    endfor

    if found_desired_nr > 0
        call s:close(a:name)
    else
        call s:open(a:name)
    endif

    if index(['top', 'bottom'], position) >= 0
        call s:restore_view()
    endif
endfunction

function! sidebar#close_side(position)
    call s:save_view()
    for name in s:position_name_map[a:position]
        if s:get_win(name) > 0
            call s:close(name)
        endif
    endfor
    call s:restore_view()
endfunction

function! sidebar#get_sidebar_name_of_current_win()
    for [name, attrs] in items(s:sidebars)
        if has_key(attrs, 'get_win') && call(attrs.get_win, []) == winnr()
            return name
        elseif call(attrs.check_win, [winnr()])
            return name
        endif
    endfor
    return ''
endfunction

function! sidebar#close_other_windows_on_same_side(current_name, timer)
    let current_name = sidebar#get_sidebar_name_of_current_win()
    if current_name !=# ''
        let position = s:sidebars[current_name].position
        for name in s:position_name_map[position]
            if name !=# current_name && s:get_win(name) > 0
                call s:close(name)
            endif
        endfor
    endif
endfunction

function! sidebar#close_all()
    call s:save_view()
    for [name, desc] in items(s:sidebars)
        if s:get_win(name) > 0
            call s:close(name)
        endif
    endfor
    call s:restore_view()
endfunction

function! sidebar#save_session()
    let g:sidebar_session = []
    for [name, desc] in items(s:sidebars)
        if s:get_win(name) > 0
            let g:sidebar_session += [name]
        endif
    endfor
    call sidebar#close_all()
endfunction

function! sidebar#load_session()
    if exists('g:sidebar_session')
        for name in g:sidebar_session
            call s:open(name)
        endfor
        " unlet g:sidebar_session
    endif
endfunction

function! s:is_sidebar(nr)
    for [name, desc] in items(s:sidebars)
        if has_key(desc, 'get_win')
            if call(desc.get_win, []) == a:nr
                return 1
            endif
        else
            if call(desc.check_win, [a:nr])
                return 1
            endif
        endif
    endfor
    return 0
endfunction

function! sidebar#close_tab_on_closing_last_buffer()
    let num_non_sidebar_wins = 0
    for i in range(1, winnr('$'))
        if !s:is_sidebar(i)
            let num_non_sidebar_wins += 1
        endif
    endfor

    if num_non_sidebar_wins == 0
        if tabpagenr('$') > 1
            confirm tabclose
        else
            confirm qall
        endif
    endif
endfunction

function! sidebar#get(...)
    if len(a:000) == 0
        return values(s:sidebars)
    elseif len(a:000) == 1
        return s:sidebars[a:1]
    else
        throw "only 1 argument is allowed"
    endif
endfunction
