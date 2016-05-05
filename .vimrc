" Activates Syntax Highlighting
syntax on

" Filetype on
filetype on

" Prevent visual mode highlighting from hiding white text
set background=dark

" Show Line Numbers
set number

" Show whitespace
set list
set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<

" Allows you to deal with multiple unsaved buffers
" simultaneously without resoring to misusing tabs
set hidden

set backspace=indent,eol,start

" Tab key inserts spaces
set expandtab

" Auto-indent (e.g. >>) width
set shiftwidth=4

" display width of a physical tab character 
set tabstop=4

" disable part-tab-part-space tabbing
set softtabstop=0

set autoindent

set whichwrap+=<,>,[,]

" New split windows go to the right pane
set splitright

" New split windows go to the bottom pane
set splitbelow

" Highlight search terms
set hlsearch

" Make common commands case-insensitive
:command Wq wq
:command W w
:command Q q
nnoremap <CR> :nohlsearch<CR><CR>
nnoremap <silent> <Space> :nohlsearch<Bar>:echo<CR>

" Highlight Current Line
set cursorline

" Highlight dynamically as pattern is typed
set incsearch

" Show partial commands as they're typed
set showcmd

" Show the filename in the window title
set title
set titleold=""
set titlestring=VIM:\ %F

" Don't show intro message when starting Vim
set shortmess=atI

" Auto-load modifications to opened files
set autoread

" Make pasting from external sources work better
set paste

" Pathogen
"execute pathogen#infect()
"filetype off
"filetype plugin indent on

" Show the file percentage progress
set ruler

" Show the full file path in the bottom status bar
set laststatus=2
"set statusline=%<%F\ %h%m%r%y%=%-14.(%l,%c%V%)\ %P

set statusline=%<%F\  "tail of the filename
set statusline+=[%{strlen(&fenc)?&fenc:'none'}] "file encoding
"set statusline+=%{&ff}] "file format ( just prints '[vim]' not sure what's the point?
set statusline+=%h      "help file flag
set statusline+=%m      "modified flag
set statusline+=%r      "read only flag
set statusline+=%y      "filetype
set statusline+=%=      "left/right separator
set statusline+=(%c,%l)
set statusline+=\ %P    "percent through file

set mouse=a

" Make pane moving and switching more like tmux
nnoremap <C-P> <C-W>
" Vertical pane resizing
nnoremap <C-P><C-H> <C-W>10<
nnoremap <C-P><C-L> <C-W>10>
" Horizontal pane resizing
nnoremap <C-P><C-K> <C-W>10+
nnoremap <C-P><C-J> <C-W>10-

" Search for the currently highlighted selection
vnoremap // y/<C-R>"<CR>

" Make j and k work better with word-wrapped lines
nnoremap j gj
nnoremap k gk

" Make yanks, deletes, etc... go to the mac system clipboard, if you're in macvim or gvim
set clipboard=unnamed
