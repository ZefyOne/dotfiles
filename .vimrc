set nocompatible

set number
set cursorline

set autoindent
set smartindent
set indentkeys+=<:>
filetype indent on
filetype plugin on

set tabstop=4
set shiftwidth=4
set expandtab
set softtabstop=4

set wrap
set linebreak
set breakindent

set ignorecase
set smartcase
set incsearch
set hlsearch

set scrolloff=8
set sidescrolloff=8

set wildmenu
set wildmode=longest:full,full

set matchtime=2
set showmatch

set laststatus=2
set statusline=%f\ %m%r%h%w\ [%p%%]\ [%l/%L]

set noerrorbells
set novisualbell
set t_vb=

set confirm

set hidden

set backup
set backupdir=~/.vim/backup
set undofile
set undodir=~/.vim/undo

syntax enable
syntax on

colorscheme habamax

inoremap <C-f> <Right>
inoremap <C-b> <Left>
inoremap { {}<Left>
inoremap ( ()<Left>
inoremap [ []<Left>
inoremap " ""<Left>
inoremap ' ''<Left>

nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>h :nohlsearch<CR>

nnoremap <C-j> 5j
nnoremap <C-k> 5k

set backspace=indent,eol,start
