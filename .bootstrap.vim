" mvs bootstrap.
"
" Keep this file small and stable.
" Its jobs are:
"   1. update the mvs repository
"   2. hand control to .init.vim

let s:repo = expand('~/.vim')


function! s:MvsUpdateRepo() abort
    " this is reload of rc scirpts
    " do nothing.
    "
	if exists('g:mvs_is_setup')
	    return
	endif

    " update is not due, also do nothing
    "
	if !mvs#update#due('mvs')
	    return
	endif

    echo "Checking remote repo"


    "
    " Fetch remote state.
    "
    call system(
                \ 'git -C ' . shellescape(s:repo) .
                \ ' fetch --quiet'
                \ )

    if v:shell_error
        return
    endif

    " get last local commit ID
    "
    let l:local = trim(system(
                \ 'git -C ' . shellescape(s:repo) .
                \ ' rev-parse HEAD'
                \ ))

    if v:shell_error
        return
    endif

    " get last remote commit ID
    "
    let l:remote = trim(system(
                \ 'git -C ' . shellescape(s:repo) .
                \ ' rev-parse @{upstream}'
                \ ))

    if v:shell_error
        return
    endif

    "
    " Update only when remote HEAD differs.
    "
    if l:local !=# l:remote
        call system(
                    \ 'git -C ' . shellescape(s:repo) .
                    \ ' merge --ff-only --quiet @{upstream}'
                    \ )

        if v:shell_error
            echohl WarningMsg
            echom 'mvs: repository update failed'
            echohl None
        else
            call mvs#update#mark('mvs')
        endif
    else
        call mvs#update#mark('mvs')
    endif
endfunction

function! s:MvsRunInit() abort
    let l:init = s:repo . '/.init.vim'

    if filereadable(l:init)
        execute 'source ' . fnameescape(l:init)
    endif
endfunction


call s:MvsUpdateRepo()
call s:MvsRunInit()
