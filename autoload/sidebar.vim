let s:sidebars = {}
let s:position_name_map = {'left': [], 'bottom': [], 'top': [], 'right': []}

function! s:find_windows_at_position(position)
    let found_nr_name_map = {}
    for i in range(1, winnr('$'))
        for name in s:position_name_map[a:position]
            if call(s:sidebars[name].check_nr, [i])
                let found_nr_name_map[i] = name
            endif
        endfor
    endfor
    return found_nr_name_map
endfunction

function! sidebar#register(desc)
    let s:sidebars[a:desc.name] = a:desc
    let s:position_name_map[a:desc.position] += [a:desc.name]
endfunction

function! sidebar#switch(name)
    let found_desired_nr = 0
    for [found_nr, found_name] in items(s:find_windows_at_position(s:sidebars[a:name].position))
        if found_name ==# a:name
            let found_desired_nr = found_nr
        else
            call call(s:sidebars[found_name].close, [])
            redraw
        endif
    endfor

    if found_desired_nr > 0
        execute found_desired_nr . 'wincmd w'
    else
        call call(s:sidebars[a:name].open, [])
    endif
endfunction

function! sidebar#close(name)
    call call(s:sidebars[name].close, [])
endfunction

function! sidebar#toggle(name)
    let found_desired_nr = 0
    for [found_nr, found_name] in items(s:find_windows_at_position(s:sidebars[a:name].position))
        if found_name ==# a:name
            let found_desired_nr = found_nr
        else
            call call(s:sidebars[found_name].close, [])
            redraw
        endif
    endfor

    if found_desired_nr > 0
        call call(s:sidebars[a:name].close, [])
    else
        call call(s:sidebars[a:name].open, [])
    endif
endfunction
