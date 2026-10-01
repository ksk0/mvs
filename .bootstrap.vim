" mvs bootstrap.
"
" Keep this file small and stable.
" Its jobs are:
"   1. update the mvs repository
"   2. hand control to .init.vim


function! s:mvs_bootstrap() abort

    let l:repo = expand('~/.vim')

    "
    " Fetch remote state.
    "
    call system(
                \ 'git -C ' . shellescape(l:repo . "-xxx") .
                \ ' fetch --quiet'
                \ )

    if !v:shell_error

        let l:local = trim(system(
                    \ 'git -C ' . shellescape(l:repo) .
                    \ ' rev-parse HEAD'
                    \ ))

        let l:remote = trim(system(
                    \ 'git -C ' . shellescape(l:repo) .
                    \ ' rev-parse @{upstream}'
                    \ ))

        "
        " Update only when remote HEAD differs.
        "
        if !v:shell_error && l:local !=# l:remote

            call system(
                        \ 'git -C ' . shellescape(l:repo) .
                        \ ' merge --ff-only --quiet @{upstream}'
                        \ )

            if v:shell_error
                echohl WarningMsg
                echom 'mvs: repository update failed'
                echohl None
            endif

        endif
    endif


    "
    " Everything after repository maintenance belongs to .init.vim.
    "
    let l:init = l:repo . '/.init.vim'

    if filereadable(l:init)
        execute 'source ' . fnameescape(l:init)
    endif

endfunction


call s:mvs_bootstrap()
