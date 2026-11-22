" Settings for VIMTUTOR ADVANCED lesson buffers (filetype: vimtutor).
"
" Deliberately NOT guarded by the standard b:did_ftplugin variable
" alone: Vim and Neovim both ship their own ftplugin for the OTHER
" tutor filetype. A dedicated guard keeps our settings authoritative
" for our lessons while remaining a good citizen everywhere else.

if exists('b:vimtutor_did_ftplugin')
  finish
endif

setlocal nonumber norelativenumber
setlocal wrap linebreak nolist breakindent
setlocal conceallevel=0 concealcursor=
setlocal nospell textwidth=0
setlocal nomodeline
setlocal noundofile
setlocal buftype=
setlocal bufhidden=
setlocal keywordprg=:help

" Scratch-copy semantics: these are real files in a temp folder, so
" edits work normally and :w writes to the copy -- :q! throws the
" whole session away, like the original tutor.

" Table-of-contents buffers: <Enter> opens the lesson under the cursor.
" Only set when vimtutor#start() loaded 00-index.
if get(b:, 'vimtutor_index', 0)
  nnoremap <buffer><silent><nowait> <CR> :call vimtutor#follow_link()<CR>
  vnoremap <buffer><silent><nowait> <CR> :<C-U>call vimtutor#follow_link()<CR>
endif

let b:vimtutor_did_ftplugin = 1
