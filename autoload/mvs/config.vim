
function! s:SourceDirectory(dir) abort
	" Source each rc file in given directory
	"
    if !isdirectory(a:dir)
        return
    endif

    if !exists('g:mvs_config_loaded')
        let g:mvs_config_loaded = "Entered SourceDir"
    else
        let g:mvs_config_loaded = 
            \ g:mvs_config_loaded . ";Entered SourceDir function"
    endif


    let l:files = globpath(a:dir, '*.vim', 0, 1)

    call sort(l:files)

    for l:file in l:files
        if filereadable(l:file)
	    let g:mvs_config_loaded = g:mvs_config_loaded . ";" . l:file
            execute 'source ' . fnameescape(l:file)
        endif
    endfor

endfunction

function! mvs#config#load() abort
    call s:SourceDirectory(expand('~/.vim/vimrc.d'))
endfunction
