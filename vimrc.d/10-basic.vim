"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Extend runtimepath to include /etc/vim/after
" this way we can have centralized "after" directory
" (otherwise it is not processed). Also include "/etc/vim"
" in runtimepath, since there is "bundle" directory, and
" now Pathogen knows where to search for it.
"
" set rtp+=/etc/vim/
set rtp+=/etc/vim/after


" Jump to the last position when reopening a file
" 
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" set colorscheme
"
colorscheme relaxedgreen

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" some basic settings for vim
"
set colorcolumn=80    " mark 80th & 100th column
set background=dark   "set dark background
set nocompatible " disables compatibility with basic vi, thus enabling advanced stuff
set showcmd      " Show (partial) command in status line.
set showmatch    " Show matching brackets.
set ignorecase   " Do case insensitive matching
set smartcase    " Do smart case matching
set incsearch    " Incremental search
set autowrite    " Automatically save before commands like :next and :make
set hidden       " Hide buffers when they are abandoned
set mouse=a      " Enable mouse usage (all modes)

set nobackup     " don't create backup file for edited file
set noundofile   " don't create undo file which would enable undoing of reopened file
set nonumber     " don't show line numbers
set hlsearch     " automatically highlight all search items
set wildmenu     " enable command completion with menu


" set paste      " enable paste with mouse - this conflicts with superTab
                 " so it is disabled
				 "

""""""""""""""""""""""""""""""""""""""""""""""""""""
" Some search/replace shortcuts:
"  \\  - no highlight
"  \A  - search and replace current word in entire
"        document
"  \S  - search and replace current word from current
"        position till end of document
"  \a  -  search for current word case sensitive
"  \s  -  search for current word case sensitive
"
nnoremap <Leader>e :NERDTreeToggle<CR>
nnoremap <Leader>\ :noh<CR>
nnoremap <Leader>A :%s/\<<C-r><C-w>\>\C//gc<LEFT><LEFT><LEFT>
nnoremap <Leader>S :.,$s/\<<C-r><C-w>\>\C//gc<LEFT><LEFT><LEFT>
nnoremap <Leader>a :%s/\<<C-r><C-w>\>//gc<LEFT><LEFT><LEFT>
nnoremap <Leader>s :.,$s/\<<C-r><C-w>\>//gc<LEFT><LEFT><LEFT>
nnoremap <Leader>c /\<<C-r><C-w>\>\C/<CR>
