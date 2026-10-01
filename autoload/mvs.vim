function! mvs#reload() abort

    if filereadable('/etc/vim/vimrc')
        source /etc/vim/vimrc
    endif

    if filereadable(expand('~/.vimrc'))
        execute 'source ' . fnameescape(expand('~/.vimrc'))
    elseif filereadable(expand('~/.vim/vimrc'))
        execute 'source ' . fnameescape(expand('~/.vim/vimrc'))
    endif

endfunction
