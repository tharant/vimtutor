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
call s:check(':DotTheme command defined', exists(':DotTheme') == 2)
call s:check('old :Theme command gone', exists(':Theme') != 2)
call s:check('theme quick maps bound',
      \ maparg('<Leader>tg', 'n') !=# '' && maparg('<Leader>tt', 'n') !=# '')
call s:check('updatetime is 250', &updatetime ==# 250)
call s:check('leader mapped (write)', maparg('<Leader>w', 'n') !=# '')
call s:check('no plugin keys mapped while plug.vim absent',
      \ maparg('<C-Space>', 'i') ==# '')
call s:check('coc keys NOT mapped (plugin missing)',
      \ maparg('gd', 'n') ==# '')
call s:check('runtimepath contains tutor home',
      \ !empty($VIMTUTOR_TEST_REPO) && stridx(&runtimepath, $VIMTUTOR_TEST_REPO) >= 0)

call add(s:log, (s:fail ? '== CONFIG CHECK FAILED ==' : '== CONFIG OK =='))
if !empty($VIMTUTOR_TEST_LOG)
  call writefile(s:log, $VIMTUTOR_TEST_LOG, 'a')
endif
if s:fail
  cq 1
else
  qa!
endif
