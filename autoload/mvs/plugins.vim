function! mvs#plugins#update() abort
    " If vim-plug module has not been configured
    " nothing to do here!
    "
    if !exists('g:plugs')
        return
    endif

    " Check whether plugin directories are missing.
    "
    for l:plugin in values(g:plugs)
        if !isdirectory(l:plugin.dir)
            PlugInstall --sync
            call mvs#reload()
            return
        endif
    endfor
endfunction
