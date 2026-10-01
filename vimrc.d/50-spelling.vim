"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" SET UP SOME SPELLING HELP
"
"
nnoremap <F10> :call SpellingOnOff()<CR>


""""""""""""""""""""""""""""""""""""""""""""""""""""
" Switch spelling mode on/of and remap some keys
" for easier navigation and correction of spelling
" errors
"
function! SpellingOnOff()
	if &spell
		call myvim#help#exit_context('spelling')

		set nospell
		nmap n n
		nmap N N
		nmap g g
		nmap . .
	else
		call myvim#help#enter_context('spelling')

		set spelllang=en_us     " set spelling language to us English
		set spell
		nnoremap n ]s
		nnoremap N [s
		nnoremap g zg
		nnoremap . :call RespellWord()<CR>
	endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""
" choose replacement word from menu, and replace
" all occurrence of bad word with selected one
" with confirmation.
"
function! RespellWord()
	let oldWord = expand("<cword>")
	let suggested = spellsuggest (oldWord,10)

	let height  = winheight('%')
	let no_sugg = len(suggested)

	let selection = [""]
	for i in range (1,no_sugg)
		call add (selection, printf ("%2d. %s",i,suggested[i-1]))
	endfor

	for i in range (1,height - no_sugg - 1)
		call add (selection,"")
	endfor

	" select replacement word
	"
	let result = inputlist (selection) - 1
	if (result < 0 || result >= no_sugg)
		return
	endif
	
	" mark the position
	"
	exec 'normal! mz'

	" replace all occurrences
	"
	let newWord = get (suggested, result)
	let replace = 's/\<' . oldWord . '\>/' . newWord . '/'

	exec ':' . replace
	exec ':.,$' . replace . 'gce'

	" go back to starting position
	"
	exec 'normal! `z`'
endfunction
