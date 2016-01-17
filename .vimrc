" Activates Syntax Highlighting
syntax on

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
imap <Tab> <C-P>
imap <S-Tab> <C-N>
nnoremap <CR> :nohlsearch<CR><CR>
nnoremap <silent> <Space> :nohlsearch<Bar>:echo<CR>
