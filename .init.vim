" mvs initialization.
"
" Repository maintenance has already finished when this file is sourced.

if exists('g:mvs_initialized')
    finish
endif

let g:mvs_initialized = 1


function! s:source_directory(dir) abort

    if !isdirectory(a:dir)
        return
    endif

    let l:files = globpath(a:dir, '*.vim', 0, 1)

    call sort(l:files)

    for l:file in l:files
        if filereadable(l:file)
            execute 'source ' . fnameescape(l:file)
        endif
    endfor

endfunction


"
" Common, Git-managed configuration.
"
call s:source_directory(expand('~/.vim/vimrc.d'))


"
" User/machine-specific configuration.
" This directory is not tracked by Git.
"
call s:source_directory(expand('~/.vim/vimrc.local.d'))
