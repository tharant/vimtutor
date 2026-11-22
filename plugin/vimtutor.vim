" vimtutor.vim -- the :Tutor command for VIMTUTOR ADVANCED.
"
" Runtime layout (loaded by both Vim 9 and Neovim through 'runtimepath'):
"   plugin/vimtutor.vim     this file: commands + defaults
"   autoload/vimtutor.vim   all behavior (kept lazy)
"   ftplugin/vimtutor.vim   per-lesson buffer settings
"   syntax/vimtutor.vim     highlight the classic tilde-bordered format
"   ftdetect/vimtutor.vim   file extension *.vimtutor
"   lessons/                the lessons themselves
"
" Both editors ship their own "tutor" runtime (markdown format, command
" :Tutor) for ft=tutor files. Our lessons use a DISTINCT filetype
" (vimtutor), and because this directory is appended to 'runtimepath',
" the command! below is defined LAST and wins over the stock command in
" both editors. The stock interactive tutor stays reachable as
" :TutorClassic (see TutorClassic below and :help vimtutor).

if exists('g:loaded_vimtutor') || &compatible
  finish
endif
let g:loaded_vimtutor = 1

" Repository root: this file is <root>/plugin/vimtutor.vim
let s:plugin_root = expand('<sfile>:p:h:h')
let g:vimtutor_home = get(g:, 'vimtutor_home', s:plugin_root)

if !exists('g:vimtutor_open') || (g:vimtutor_open !=# 'tab' && g:vimtutor_open !=# 'split')
  let g:vimtutor_open = 'tab'
endif

" :Tutor            the table of contents
" :Tutor 3          lesson 3 by number   (also :Tutor 03)
" :Tutor splits     lesson matching a name fragment
" Tab completes all three forms.
command! -nargs=? -bar -complete=customlist,vimtutor#complete
      \ Tutor call vimtutor#start(<q-args>)

" The stock markdown tutor that ships with Vim 9 / Neovim.
command! -nargs=? -bar -complete=custom,tutor#TutorCmdComplete
      \ TutorClassic call vimtutor#classic(<q-args>)
