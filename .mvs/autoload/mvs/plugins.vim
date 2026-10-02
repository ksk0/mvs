function! s:PluginsInstall() abort
    PlugInstall --sync
endfunction

function! mvs#plugins#update() abort
    " If vim-plug module has not been configured
    " nothing to do here!
    "
    if !exists('g:plugs')
        return
    endif

    " Check whether plugin directories are missing.
    "
    let s:need_update = 0

    for l:plugin in values(g:plugs)
        if !isdirectory(l:plugin.dir)
            let s:need_update = 1
            break
        endif
    endfor

    if !s:need_update && !mvs#update#due('plugins')
        return
    endif

    call s:PluginsInstall()
    call mvs#reload()
    call mvs#update#mark('plugins')
endfunction
