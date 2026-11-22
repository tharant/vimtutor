" Minimal test vimrc: like a barebones user config, just enough for the
" plugin to load normally. Expand of <script> resolves to this file, so
" the repo root is derived without external knowledge.

set nocompatible
filetype plugin indent on
syntax on
let &runtimepath = escape(expand('<sfile>:p:h:h'), ', \') . ',' . &runtimepath
