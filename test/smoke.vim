" Headless smoke tests for the vimtutor plugin.
" Run via test/run.sh (which puts the repo on 'runtimepath' and runs
" this under both Vim and Neovim). Results print to stdout and append
" to $VIMTUTOR_TEST_LOG so silent (-es / --headless) runs stay
" inspectable.

set nocompatible
filetype plugin indent on
syntax on

let s:fail = 0
let s:log = []
let s:orig_cwd = getcwd()

function! s:check(name, cond) abort
  let l:line = (a:cond ? 'PASS: ' : 'FAIL: ') . a:name
  call add(s:log, l:line)
  echo l:line
  if !a:cond
    let s:fail = 1
  endif
endfunction

call s:check(':Tutor command defined', exists(':Tutor') == 2)
call s:check(':TutorClassic command defined', exists(':TutorClassic') == 2)
call s:check('plugin set g:vimtutor_home', exists('g:vimtutor_home'))
call s:check('lesson list finds the index',
      \ exists('g:vimtutor_home') && !empty(vimtutor#lessons()))

" 1. Index opens in the sandbox as a scratch copy.
call vimtutor#start('')
call s:check('index buffer title', join(getline(1, 3), ' ') =~# 'VIMTUTOR ADVANCED')
call s:check('filetype is vimtutor', &filetype ==# 'vimtutor')
call s:check('buffer is NOT the source lesson', expand('%:p:h') !=# s:orig_cwd)
call s:check('window cwd is the sandbox', getcwd() !=# s:orig_cwd)
call s:check('index link mapping installed', maparg('<CR>', 'n') !=# '')
call s:check('syntax loaded', get(b:, 'current_syntax', '') ==# 'vimtutor')
call s:check('vimtutorTilde highlight group exists',
      \ hlexists('vimtutorTilde') != 0)
call s:check('buffer is modifiable', &modifiable)
let s:tabs_after_first = tabpagenr('$')

" 2. The <Enter> link logic, driven directly.
"    NB: at script top level only s: names persist across lines --
"    l: variables are function-local and would silently no-op.
for s:l in range(1, line('$'))
  if getline(s:l) =~# '|03|'
    call cursor(s:l, 1)
    break
  endif
endfor
call vimtutor#follow_link()
call s:check('follow_link opened lesson 03', expand('%:t') =~# '^03-')
call s:check('index marker cleared on lesson buffers', !exists('b:vimtutor_index'))

" 3. Resolution by number and by name fragment; window is reused.
call vimtutor#start('cheat')
call s:check('resolve by name (cheat -> 13)', expand('%:t') =~# '^13-')
call vimtutor#start('03')
call s:check('resolve by number 3 -> 03', expand('%:t') =~# '^03-')
call s:check('no tab stacking across lesson hops',
      \ tabpagenr('$') == s:tabs_after_first)

" 4. Sandbox materialization: lessons AND demo files.
call s:check('lesson files copied', filereadable(getcwd() . '/04-macros.vimtutor'))
call s:check('demo files copied', filereadable(getcwd() . '/demo/lang-demo.js'))

" 5. The sandbox is a real copy: writing touches only the temp dir.
call setline(1, ['EDITED'])
setlocal nomodified
silent! write
call s:check('write works on the scratch copy', filereadable(expand('%:p')))
call s:check('source lesson file untouched',
      \ readfile(vimtutor#lessons()[3])[0] !=# 'EDITED')

" 6. A bad argument lands back on the index, gracefully.
call vimtutor#start('no-such-lesson')
call s:check('bad arg falls back to the index', expand('%:t') =~# '^00-')

" 7. Completion is wired to the real lesson list.
let s:comp = vimtutor#complete('', '', 0)
call s:check('completion lists all lessons', len(s:comp) == len(vimtutor#lessons()))

call add(s:log, (s:fail ? '== SMOKE FAILED ==' : '== SMOKE OK =='))
if !empty($VIMTUTOR_TEST_LOG)
  call writefile(s:log, $VIMTUTOR_TEST_LOG, 'a')
endif
if s:fail
  cq 1
else
  qa!
endif
