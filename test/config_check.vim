" Assertions for config/vimrc.common, run AFTER the test rc sourced it.
" See config_check.sh for the harness (isolated HOME, no plugins).

let s:fail = 0
let s:log = ['== config check ==']

function! s:check(name, cond) abort
  call add(s:log, (a:cond ? 'PASS: ' : 'FAIL: ') . a:name)
  if !a:cond
    let s:fail = 1
  endif
endfunction

call s:check(':Tutor available via self-sufficient rtp', exists(':Tutor') == 2)
call s:check('mapleader is space', g:mapleader ==# ' ')
call s:check('hidden on', &hidden)
call s:check('relative numbers on', &relativenumber)
call s:check('splits open below/right', &splitbelow && &splitright)
call s:check('smartcase search', &smartcase)
call s:check('undo directory created and undofile on',
      \ &undofile && isdirectory(expand(&undodir)))
call s:check('undodir is inside the isolated data dir',
      \ stridx(expand(&undodir), 'vimtutordata') >= 0)
call s:check(':Theme command defined', exists(':Theme') == 2)
call s:check('leader mapped (write)', maparg('<Leader>w', 'n') !=# '')
call s:check('no plugin keys mapped while plug.vim absent',
      \ maparg('<C-Space>', 'i') ==# '')
call s:check('coc keys NOT mapped (plugin missing)',
      \ maparg('gd', 'n') ==# '')
call s:check('runtimepath contains tutor home',
      \ !empty($VIMTUTOR_TEST_REPO) && stridx(&runtimepath, $VIMTUTOR_TEST_REPO) >= 0)


" Scala 3 toolchain wiring (fake install made by config_check.sh).
call s:check('scala bin dir leads $PATH',
      \ stridx($PATH, g:vimtutor_data . '/scala/bin') >= 0)
call s:check('metals resolves from the scala bin dir',
      \ exepath('metals') ==# g:vimtutor_data . '/scala/bin/metals')
call s:check('fetched JDK becomes $JAVA_HOME',
      \ $JAVA_HOME ==# $VIMTUTOR_TEST_JDK)
call s:check('fetched JDK bin is on $PATH',
      \ stridx($PATH, $VIMTUTOR_TEST_JDK . '/bin') >= 0)
call s:check('no Metals coc config while coc is absent',
      \ !exists('g:coc_user_config'))
new
setfiletype scala
call s:check('scala buffers indent by 2', &l:shiftwidth == 2)
bwipe!

call add(s:log, (s:fail ? '== CONFIG CHECK FAILED ==' : '== CONFIG OK =='))
if !empty($VIMTUTOR_TEST_LOG)
  call writefile(s:log, $VIMTUTOR_TEST_LOG, 'a')
endif
if s:fail
  cq 1
else
  qa!
endif
