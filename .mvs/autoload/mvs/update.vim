function! mvs#update#slot() abort
    return strftime('%Y-%m-%d', localtime() - 5 * 60 * 60)
endfunction

function! mvs#update#due(name) abort
    if get(g:, 'mvs_force_update', 0)
        return 1
    endif

    let l:file = expand('~/.vim/.state/' . a:name)

    if !filereadable(l:file)
        return 1
    endif

    let l:last = get(readfile(l:file), 0, '')

    return l:last !=# mvs#update#slot()
endfunction


function! mvs#update#mark(name) abort
    let l:dir = expand('~/.vim/.state')

    if !isdirectory(l:dir)
        call mkdir(l:dir, 'p')
    endif

    call writefile([mvs#update#slot()], l:dir . '/' . a:name)
endfunction


function! mvs#update#all() abort
    let g:mvs_force_update = 1
    unlet! g:mvs_is_setup

    try
        execute 'source ' . fnameescape(expand('~/.vim/.bootstrap.vim'))
    finally
        unlet! g:mvs_force_update
    endtry
endfunction
