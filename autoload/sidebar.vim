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

function! sidebar#switch(name)
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
endfunction

function! sidebar#close(name)
    let nr = 0
    for i in range(1, winnr('$'))
        if call(s:sidebars[a:name].check_win, [i])
            call s:call_or_exec(s:sidebars[a:name].close, [])
        endif
    endfor
endfunction

function! sidebar#toggle(name)
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
endfunction

function! sidebar#close_side(position)
    for name in s:position_name_map[a:position]
        call call(s:sidebars[name].close, [])
    endfor
    redraw
endfunction

function! sidebar#close_all()
    for [name, desc] in s:sidebars
        call call(desc.close, [])
    endfor
    redraw
endfunction
