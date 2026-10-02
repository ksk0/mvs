" mvs initialization.
"
" Repository maintenance has already finished when this file is sourced.

function! s:LoadVimPlug() abort
    " Install vim-plug if one is not already
    " installed.
    "
    if exists('g:mvs_is_setup')
        return
    endif

    let s:autoload = g:mvs_plugin_path . '/autoload'
    let s:plugvim  = s:autoload . '/plug.vim'

    if filereadable(s:plugvim) && !mvs#update#due('vimplug')
        return
    endif

    if !isdirectory(s:autoload)
        call mkdir(s:autoload, 'p')
    endif

    call system(
                \ 'wget -qO ' . shellescape(s:plugvim) . ' ' .
                \ shellescape('https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim')
                \ )

    if v:shell_error
        echohl ErrorMsg
        echom 'mvs: failed to download vim-plug'
        echohl None
    else
        call mvs#update#mark('vimplug')
    endif
endfunction

function! s:LoadPlugins(plugs) abort
    let l:plist = expand('~/.vim/' . a:plugs)

    if !filereadable(l:plist)
        let l:plist .= '.vim'
        if !filereadable(l:plist)
            return
        endif
    endif

    call plug#begin('~/.vim/plugged')
    execute 'source ' . fnameescape(l:plist)
    call plug#end()
endfunction

function! s:RegisterAutoSetup() abort
    " Prepare autocomand group which would run
    " PlugInstall on Vim entry if needed.
    "
    augroup mvs_setup
        autocmd!
        autocmd VimEnter * call mvs#plugins#update()
        autocmd VimEnter * call mvs#config#load()
    augroup END
endfunction

function! s:LoadUserConfig() abort
    if v:vim_did_enter
        return
    endif

    call mvs#config#load()
endfunction

call s:LoadVimPlug()
call s:LoadPlugins('.plugins')
call s:LoadPlugins('plugins')
call s:LoadUserConfig()
call s:RegisterAutoSetup()

let g:mvs_is_setup = 1
