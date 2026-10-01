"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" SETTINGS SIGNIFICANT FOR SYNTAX (HIGHLIGHTING, ...)
"
"
let g:zsh_fold_enable = 1


""""""""""""""""""""""""""""""""""""""""""""""""""""
" set default tab space and auto indent
"
set ts=4             " default tab width is 4 spaces
set sw=4             " default backspace width is 4 spaces
set ai               " auto indent lines


""""""""""""""""""""""""""""""""""""""""""""""""""""
" file type detection is crucial for syntax handling
"
filetype on          " enable detection of filetype
filetype plugin on   " load plugins for detected filetypes
filetype indent on   " enable indention rules for detected filetypes


""""""""""""""""""""""""""""""""""""""""""""""""""""
" syntax and folding
"
syntax on

set foldenable
set foldlevelstart=0

" --- Shell fold color ---
"
autocmd FileType sh highlight Folded ctermfg=8


""""""""""""""""""""""""""""""""""""""""""""""""""""
" manually force filetype detection and resyncing of
" document presentation (useful if presentation
" gets mashed), and when creating new file (type can't
" be detected on newly created files)
"
" noremap <F9> :filetype detect<CR>:syntax sync fromstart<CR>zM

""""""""""""""""""""""""""""""""""""""""""""""""""""
" manually convert tabs into spaces
"
noremap <F12> :set expandtab<CR>:retab<CR>:set noexpandtab<CR>
