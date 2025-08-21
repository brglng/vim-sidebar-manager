let s:sidebars = {}
let s:position_name_map = {'left': [], 'right': [], 'top': [], 'bottom': []}

function! sidebar#register(desc)
    let s:sidebars[a:desc.name] = a:desc
    let s:position_name_map[a:desc.position] += [a:desc.name]
endfunction

function! s:register_g_sidebars()
    if exists('g:sidebar')
        for [name, attrs] in items(g:sidebar)
            let desc = copy(attrs)
            let desc['name'] = name
            call sidebar#register(desc)
        endfor
    elseif exists('g:sidebars')
        for [name, attrs] in items(g:sidebars)
            let desc = copy(attrs)
            let desc['name'] = name
            call sidebar#register(desc)
        endfor
    endif
endfunction

call s:register_g_sidebars()

function! s:call_or_exec(func_or_cmd)
    if exists('v:t_func') && type(a:func_or_cmd) is v:t_func
        call call(a:func_or_cmd, [])
    else
        execute a:func_or_cmd
    endif
endfunction

function! s:call_or_eval(func_or_expr)
    if exists('v:t_func') && type(a:func_or_expr) is v:t_func
        return call(a:func_or_expr, [])
    else
        return eval(a:func_or_expr)
    endif
endfunction

function! s:filter_win(name, nr)
    if has_key(s:sidebars[a:name], 'filter')
        return call(s:sidebars[a:name].filter, [a:nr])
    else
        return call(s:sidebars[a:name].check_win, [a:nr])
    endif
    return 0
endfunction

function! s:get_win(name)
    if has_key(s:sidebars[a:name], 'get_win')
        return s:call_or_eval(s:sidebars[a:name].get_win)
    else
        for i in range(1, winnr('$'))
            if s:filter_win(a:name, i)
                return i
            endif
        endfor
    endif
    return 0
endfunction

function! s:width(name)
    let w = 0
    if has_key(s:sidebars[a:name], 'width')
        let w = s:sidebars[a:name].width
    elseif s:sidebars[a:name].position ==# 'left'
        let w = g:sidebar_left_width
    elseif s:sidebars[a:name].position ==# 'right'
        let w = g:sidebar_right_width
    endif
    if w < 1
        let w = float2nr(w * &columns)
    endif
    return w
endfunction

function! s:height(name)
    let h = 0
    if has_key(s:sidebars[a:name], 'height')
        let h = s:sidebars[a:name].height
    elseif s:sidebars[a:name].position ==# 'top'
        let h = g:sidebar_top_height
    elseif s:sidebars[a:name].position ==# 'bottom'
        let h = g:sidebar_bottom_height
    endif
    if h < 1
        let h = float2nr(h * &lines)
    endif
    return h
endfunction

function! s:move(name)
    if has_key(s:sidebars[a:name], 'move')
        return s:sidebars[a:name].move
    else
        return g:sidebar_move
    end
endfunction

function! s:opts(name)
    let opts = copy(g:sidebar_opts)
    if has_key(s:sidebars[a:name], 'opts')
        let opts = extend(opts, s:sidebars[a:name].opts)
    endif
    return opts
endfunction

function! s:resize_win(name)
    if s:sidebars[a:name].position ==# 'left' || s:sidebars[a:name].position ==# 'right'
        execute s:width(a:name) . 'wincmd |'
    else
        execute s:height(a:name) . 'wincmd _'
    endif
endfunction

function! s:setup_win(name, nr)
    if s:move(a:name)
        if s:sidebars[a:name].position ==# 'left'
            execute 'wincmd H'
        elseif s:sidebars[a:name].position ==# 'right'
            execute 'wincmd L'
        elseif s:sidebars[a:name].position ==# 'top'
            execute 'wincmd K'
        elseif s:sidebars[a:name].position ==# 'bottom'
            execute 'wincmd J'
        endif
    endif

    call s:resize_win(a:name)

    for [opt, val] in items(s:opts(a:name))
        if exists('&' . opt)
            call setbufvar('%', '&' . opt, val)
        endif
    endfor

    if maparg('q', 'n') ==# ''
        nnoremap <buffer> <silent> q <C-w>q
    endif
endfunction

function! s:open(name)
    call s:call_or_exec(s:sidebars[a:name].open)
    let nr = s:get_win(a:name)
    if winnr() != nr
        execute nr . 'wincmd w'
    endif
endfunction

function! s:wait_for_close(position)
    while 1
        let found_wins = s:find_windows_at_position(a:position)
        sleep 30m
        if len(found_wins) == 0
            break
        endif
    endwhile
endfunction

function! s:close(name)
    if has_key(s:sidebars[a:name], 'close')
        call s:call_or_exec(s:sidebars[a:name].close)
    else
        let nr = s:get_win(a:name)
        if nr > 0
            execute nr . 'wincmd q'
        endif
    endif
    call s:wait_for_close(s:sidebars[a:name].position)
endfunction

function! s:dont_close(prev, next)
    if has_key(s:sidebars[a:next], 'dont_close')
        if type(s:sidebars[a:next].dont_close) is v:t_string
            return match(a:prev, s:sidebars[a:next].dont_close) >= 0
        elseif type(s:sidebars[a:next].dont_close) is v:t_list
            for pattern in s:sidebars[a:next].dont_close
                if match(a:prev, pattern) >= 0
                    return v:true
                endif
            endfor
        endif
    endif
    return v:false
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

if exists('&splitkeep')
    function! s:save_view()
    endfunction

    function! s:restore_view()
    endfunction
else
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
endif

function! sidebar#is_sidebar(nr)
    for [name, desc] in items(s:sidebars)
        if has_key(desc, 'get_win')
            if s:call_or_eval(desc.get_win) == a:nr
                return 1
            endif
        else
            if has_key(desc, 'filter')
                if call(desc.filter, [a:nr])
                    return 1
                endif
            else
                if call(desc.check_win, [a:nr])
                    return 1
                endif
            endif
        endif
    endfor
    return 0
endfunction

function! sidebar#get_current_sidebar()
    let nr = winnr()
    for [name, desc] in items(s:sidebars)
        if s:get_win(name) == nr
            return [nr, desc]
        endif
    endfor
    return [0, {}]
endfunction

function! s:setup_current_sidebar_window()
    let save_lazyredraw = &lazyredraw
    set lazyredraw
    let [nr, desc] = sidebar#get_current_sidebar()
    if nr > 0
        call s:setup_win(desc.name, nr)
    endif
    let &lazyredraw = save_lazyredraw
endfunction

nnoremap <silent> <Plug>(sidebar-setup-current-sidebar-window) :call <SID>setup_current_sidebar_window()<CR>
vnoremap <silent> <Plug>(sidebar-setup-current-sidebar-window) :call <SID>setup_current_sidebar_window()<CR>
snoremap <silent> <Plug>(sidebar-setup-current-sidebar-window) <C-o>:call <SID>setup_current_sidebar_window()<CR>
inoremap <silent> <Plug>(sidebar-setup-current-sidebar-window) <C-o>:call <SID>setup_current_sidebar_window()<CR>
if has('nvim')
    tnoremap <silent> <Plug>(sidebar-setup-current-sidebar-window) <C-\><C-o>:call <SID>setup_current_sidebar_window()<CR>
else
    tnoremap <silent> <Plug>(sidebar-setup-current-sidebar-window) <C-_><C-o>:call <SID>setup_current_sidebar_window()<CR>
endif

function! sidebar#setup_current_sidebar_window()
    if sidebar#is_sidebar(winnr())
        call feedkeys("\<Plug>(sidebar-setup-current-sidebar-window)")
    endif
endfunction

function! sidebar#switch(name)
    let position = s:sidebars[a:name].position

    if index(['top', 'bottom'], position) >= 0
        call s:save_view()
    endif

    let found_desired_nr = 0
    let found_wins = s:find_windows_at_position(s:sidebars[a:name].position)
    for [found_nr, found_name] in items(found_wins)
        if found_name ==# a:name
            let found_desired_nr = found_nr
        else
            if !s:dont_close(found_name, a:name)
                call s:close(found_name)
            endif
        endif
    endfor

    for [found_nr, found_name] in items(found_wins)
        if found_nr == winnr()
            wincmd p
            break
        endif
    endfor

    if found_desired_nr > 0
        if winnr() != found_desired_nr
            execute found_desired_nr . 'wincmd w'
        endif
    else
        call s:open(a:name)
    endif

    if index(['top', 'bottom'], position) >= 0
        call s:restore_view()
    endif
endfunction

function! sidebar#open(name)
    return sidebar#switch(a:name)
endfunction

function! sidebar#close(name)
    let position = s:sidebars[a:name].position

    if index(['top', 'bottom'], position) >= 0
        call s:save_view()
    endif

    if has_key(a:name, 'get_win')
        if s:call_or_eval(s:sidebars[a:name].get_win) > 0
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
        else
            if !s:dont_close(found_name, a:name)
                call s:close(found_name)
            endif
        endif
    endfor

    for [found_nr, found_name] in items(found_wins)
        if found_nr == winnr()
            wincmd p
            break
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

function! sidebar#close_side_except(position, name)
    call s:save_view()
    for name in s:position_name_map[a:position]
        if name !=# a:name && s:get_win(name) > 0
            call s:close(name)
        endif
    endfor
    call s:restore_view()
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

function! s:is_sidebar(nr)
    for [name, desc] in items(s:sidebars)
        if has_key(desc, 'get_win')
            if s:call_or_eval(desc.get_win) == a:nr
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

function! sidebar#open_last_help(cmd)
    let bufnr = 0
    let lastused = 0
    for nr in range(1, bufnr('$'))
        if getbufvar(nr, '&buftype') ==# 'help'
            if nr > bufnr || getbufinfo(nr)[0].lastused > lastused
                let bufnr = nr
                let lastused = getbufinfo(nr)[0].lastused
            endif
        endif
    endfor
    execute a:cmd . ' help'
    if bufnr > 0
        execute 'buffer ' . bufnr
    endif
endfunction
