" Autoloaded behavior for VIMTUTOR ADVANCED (:Tutor).
"
" Sandbox model, exactly like the original vimtutor: lesson files are
" COPIED into a throwaway directory once per session and the copies are
" opened for editing. Nothing you type can reach the real lessons, and
" quitting with :q! discards all practice changes.

function! vimtutor#lessons() abort
  return sort(split(globpath(g:vimtutor_home . '/lessons', '*.vimtutor'), "\n"))
endfunction

function! s:index_path() abort
  for l:f in vimtutor#lessons()
    if fnamemodify(l:f, ':t') =~# '^00-'
      return l:f
    endif
  endfor
  return ''
endfunction

" Command-line completion: numbers ("03"), name fragments ("splits"),
" or nothing (every lesson).
function! vimtutor#complete(ArgLead, CmdLine, CursorPos) abort
  let l:out = []
  for l:f in vimtutor#lessons()
    let l:name = fnamemodify(l:f, ':t:r')
    if empty(a:ArgLead) || l:name =~# ('^' . escape(a:ArgLead, '.*[^]\~$'))
      call add(l:out, l:name)
    endif
  endfor
  return l:out
endfunction

function! s:resolve(arg) abort
  let l:arg = trim(a:arg)
  if empty(l:arg)
    return s:index_path()
  endif
  if l:arg =~# '^\d\+$'
    " Tolerate 3 vs 03.
    let l:pad = substitute(l:arg, '^\d$', '0&', '')
    for l:f in vimtutor#lessons()
      if fnamemodify(l:f, ':t') =~# ('^' . l:pad . '-')
        return l:f
      endif
    endfor
  else
    let l:needle = tolower(l:arg)
    for l:f in vimtutor#lessons()
      if stridx(tolower(fnamemodify(l:f, ':t')), l:needle) >= 0
        return l:f
      endif
    endfor
  endif
  return ''
endfunction

function! s:sandbox_dir() abort
  if !exists('s:scratch_dir')
    let s:scratch_dir = tempname() . '-tutor'
    " Reuse the cache across calls in the same session.
  endif
  return s:scratch_dir
endfunction

" Copy every lesson plus the demo files into the scratch folder.
" idempotent within a session; a fresh session gets fresh copies.
function! s:materialize() abort
  let l:dir = s:sandbox_dir()
  if exists('s:materialized')
    return l:dir
  endif
  call mkdir(l:dir . '/demo', 'p')
  let l:sources = vimtutor#lessons()
        \ + split(globpath(g:vimtutor_home . '/lessons/demo', '*'), "\n")
  for l:src in l:sources
    if !filereadable(l:src) | continue | endif
    let l:base = fnamemodify(l:src, ':t')
    if l:src =~# '/demo/'
      call writefile(readfile(l:src), l:dir . '/demo/' . l:base)
    else
      call writefile(readfile(l:src), l:dir . '/' . l:base)
    endif
  endfor
  let s:materialized = 1
  return l:dir
endfunction

function! s:in_tutor_buffer() abort
  return &filetype ==# 'vimtutor' && filereadable(expand('%:p'))
        \ && expand('%:t') =~? '\.vimtutor$'
endfunction

function! vimtutor#start(arg) abort
  let l:src = s:resolve(trim(a:arg))
  if empty(l:src) && !empty(trim(a:arg))
    echohl WarningMsg
    echom printf("vimtutor: no lesson matches '%s' -- opening the index",
          \ trim(a:arg))
    echohl None
  endif
  if empty(l:src)
    let l:src = s:index_path()
  endif
  if empty(l:src)
    echohl Error
    echom 'vimtutor: no lessons found under ' . g:vimtutor_home . '/lessons'
    echohl None
    return
  endif

  let l:dir = s:materialize()
  let l:target = l:dir . '/' . fnamemodify(l:src, ':t')
  let l:is_index = fnamemodify(l:src, ':t') =~# '^00-'

  " First lesson: honor g:vimtutor_open. Between lessons: reuse the
  " tutor window so navigations do not stack windows.
  if s:in_tutor_buffer()
    execute 'edit' fnameescape(l:target)
  elseif g:vimtutor_open ==# 'tab'
    execute 'tabnew' fnameescape(l:target)
  else
    execute 'new' fnameescape(l:target)
  endif

  " The index gets <Enter>-to-open; lessons do not. Set BEFORE the
  " ftplugin runs, otherwise it misses the flag. Clear stale markers on
  " non-index buffers when reusing the tutor window.
  if l:is_index
    let b:vimtutor_index = 1
  else
    silent! unlet b:vimtutor_index
  endif

  " Window-local working dir so :e, :find, :vimgrep, netrw, and the
  " lessons' own instructions all resolve inside the sandbox.
  silent! execute 'lcd' fnameescape(l:dir)

  setlocal filetype=vimtutor
  " NB: ftdetect may already have applied the ftplugin while :tabnew read
  " the file -- i.e. BEFORE the index marker above existed. Deliberately
  " load it again now that the marker is set; the guards inside keep this
  " idempotent, and syntax never reloads twice.
  silent! unlet b:vimtutor_did_ftplugin
  runtime! ftplugin/vimtutor.vim
  runtime! syntax/vimtutor.vim

  normal! gg0
endfunction

function! vimtutor#follow_link() abort
  if get(b:, 'vimtutor_index', 0)
    let l:num = matchstr(getline('.'), '|\zs\d\+\ze|')
    if !empty(l:num)
      call vimtutor#start(l:num)
    endif
  endif
endfunction

" The stock interactive tutorial that ships with Vim 9 and Neovim
" (markdown format, :Tutor in stock form). Kept here so nothing is lost
" by our command override.
function! vimtutor#classic(arg) abort
  if exists('*tutor#TutorCmd')
    call tutor#TutorCmd(a:arg)
  else
    echohl WarningMsg
    echom 'vimtutor: the stock markdown tutor is unavailable here;'
          \ ': run "vimtutor" in a shell instead.'
    echohl None
  endif
endfunction
