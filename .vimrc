" Set the colorscheme to something not terrible
colorscheme default

" Use Vim settings and not vi settings
set nocompatible

" Change <Leader>
let mapleader = ","

" Activates Syntax Highlighting
syntax on

" Filetype on
filetype on

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

Plugin 'rodjek/vim-puppet'
Plugin 'ekalinin/Dockerfile.vim'
Plugin 'davidhalter/jedi-vim'
Plugin 'hashivim/vim-terraform'
Plugin 'lepture/vim-jinja'
Plugin 'robbles/logstash.vim'
Plugin 'tsandall/vim-rego'
Plugin 'axvr/org.vim'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

" Prevent visual mode highlighting from hiding white text
set background=dark

" Show Line Numbers
set number

" Make the dots that I like to use for trailing whitespace (just below) work correctly
scriptencoding utf-8
set encoding=utf-8

" Show whitespace
set list
set listchars=tab:>-,trail:·,extends:>,precedes:<,eol:$

" Allows you to deal with multiple unsaved buffers
" simultaneously without resorting to misusing tabs
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
:command! Wq wq
:command! W w
:command! Q q
nnoremap <CR> :nohlsearch<CR><CR>
nnoremap <silent> <Space> :nohlsearch<Bar>:echo<CR>

" Highlight Current Line
set cursorline

" Highlight Current Column
set cursorcolumn

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

" Pathogen
"execute pathogen#infect()
"filetype off
"filetype plugin indent on
"call pathogen#infect()
syntax on
filetype on
filetype plugin on
filetype indent on

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
set statusline+=\ %{\ line2byte(line(\"$\")+1)-1\ }Bytes\ 
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

"split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Search for the currently highlighted selection
vnoremap // y/<C-R>"<CR>

" Make j and k work better with word-wrapped lines
nnoremap j gj
nnoremap k gk

" Make yanks, deletes, etc... go to the mac system clipboard, if you're in macvim or gvim
if $TMUX == ''
    set clipboard=unnamed
endif

" Make two exclamations save the file using sudo
cmap w!! w !sudo tee %


" Syntastic stuff... was causing too many false positive syntax failures... revisit later!
"set statusline+=%#warningmsg#
"set statusline+=%{SyntasticStatuslineFlag()}
"set statusline+=%*
"
"let g:syntastic_always_populate_loc_list = 1
"let g:syntastic_auto_loc_list = 1
"let g:syntastic_check_on_open = 1
"let g:syntastic_check_on_wq = 0

" Comment out shellcmdflag for now. Sourcing the bash aliases
" alone via $BASH_ENV appears to be a better solution
":set shellcmdflag=-lic

let $BASH_ENV = "~/.bash_aliases"

" Associate *.disabled with yaml filetype
autocmd BufRead,BufNewFile *.disabled setfiletype yaml

" Associate *.pp with json filetype
autocmd BufNewFile,BufRead *.pp set ft=javascript tabstop=2 softtabstop=2 shiftwidth=2

" Associate *.tf with json filetype
autocmd BufNewFile,BufRead *.tf set ft=yaml tabstop=2 softtabstop=2 shiftwidth=2
"
" Associate *.tf with json filetype
autocmd BufNewFile,BufRead *.hcl set ft=yaml tabstop=2 softtabstop=2 shiftwidth=2

" Associate *.conf with json filetype
autocmd BufNewFile,BufRead *.conf set ft=javascript

" Associate *.groovy with groovy syntax
autocmd BufNewFile,BufRead *.groovy  setf groovy

" Associate Jenkinsfile with groovy syntax
autocmd BufNewFile,BufRead Jenkinsfile setf groovy

" In go files, don't expand tabs to spaces, since actual tab characters
" appear to be more preffered (??)
autocmd FileType go set noexpandtab shiftwidth=4 softtabstop=0

" In makefiles, don't expand tabs to spaces, since actual tab characters are
" needed, and have indentation at 8 chars to be sure that all indents are tabs
autocmd FileType make set noexpandtab shiftwidth=8 softtabstop=0

" Add completion for xHTML
autocmd FileType xhtml,html set omnifunc=htmlcomplete#CompleteTags

" Add completion for XML
autocmd FileType xml set omnifunc=xmlcomplete#CompleteTags

" Don't create .swp files
set nobackup
set noswapfile

" Remember more commands and search history
set history=1000

" Use many levels of undo
set undolevels=1000

" Disable bell
set visualbell
set noerrorbells

" Enable extended % matching
" % matches on if/else, html tags, etc.
runtime macros/matchit.vim

" Bash-like filename completion
set wildmenu
set wildmode=list:longest
set wildignore=*.o,*.pyc

" Make it easy to toggle between showing whitespace, eol, etc...
nmap <silent> <leader>w :set nolist!<CR>

" Try to eliminate dependency on <Esc> key
imap jj <Esc>

" Vi-style editing in the command-line (kind of annoying)
"nnoremap : q:a
"nnoremap / q/a
"nnoremap ? q?a

" Keep undo history across sessions, by storing in file.
" Only works all the time.
silent !mkdir ~/.vim/backups > /dev/null 2>&1
set undodir=~/.vim/backups
set undofile

set guifont=Menlo\ Regular:h18

" For the Vim-terraform plugin
let g:terraform_align=1

" Give a shortcut for formatting valid json inside vim
com! JSON %!python -m json.tool


" Easily toggle spelling
command Spell setlocal spell! spelllang=en_us

