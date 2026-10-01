" mvs initialization.
"
" Repository maintenance has already finished when this file is sourced.

function! s:EnsureVimPlug() abort
	" Install vim-plug if one is not already 
	" installed.
	"
	if exists('g:mvs_is_setup')
	    return
	endif

	let s:autoload = expand('~/.vim/autoload')
	let s:plugvim  = s:autoload . '/plug.vim'

	if filereadable(s:plugvim)
		return
	endif

	if !isdirectory(s:autoload)
	    call mkdir(s:autoload, 'p')
	endif
	
	if !filereadable(s:plugvim)
	    call system(
	                \ 'wget -qO ' . shellescape(s:plugvim) . ' ' .
	                \ shellescape('https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim')
	                \ )
	
	    if v:shell_error
	        echohl ErrorMsg
	        echom 'mvs: failed to download vim-plug'
	        echohl None
	    endif
	endif
endfunction

function! s:RegisterPluginUpdate() abort
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


call s:EnsureVimPlug()
call s:RegisterPluginUpdate()
call s:LoadUserConfig()

let g:mvs_is_setup = 1
