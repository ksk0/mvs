"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" SET UP SOME SwapLimelight
"
"
nnoremap <C-S-l> :call SwapLimelight()<CR>

function! SwapLimelight()
	if exists ("g:limelight_conceal_ctermfg")
		unlet g:limelight_conceal_ctermfg
		:Limelight!
	else
		let g:limelight_conceal_ctermfg = 240
		:Limelight
	endif
endfunction

