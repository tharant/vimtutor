" Syntax for VIMTUTOR ADVANCED lesson files (the classic format of the
" original vimtutor: tilde-bordered practice blocks, ---> markers,
" Ex commands called out in prose, and <Special> key notation).
"
" Design note: the tilde is highlighted ONLY as a leading character --
" the rest of the line stays normal text, so Ex commands and key names
" keep their highlights inside practice blocks.

if exists('b:current_syntax')
  finish
endif

syn sync minlines=100

" The fake window border: the tilde only. (Backslashed: a bare ~ in a
" pattern is the "previous substitute" atom, not a literal tilde.)
syn match   vimtutorTilde   '^\s*\zs\~'

" The "====" box lines and title text between them.
" (a title line is "="-prefixed and contains something that is not "=")
syn match   vimtutorBox     '^=\+$'
syn match   vimtutorTitle   '^=.*[^=].*$'

" Practice targets, like the original tutor.
syn match   vimtutorTarget  '--->'

" Ex commands in prose: :split, :reg, :g//, :%s/..., :'<,'>s/...
syn match   vimtutorCmd     ':\<\a\w*'
syn match   vimtutorCmd     '\V:%s\?'
syn match   vimtutorCmdEx   "\V:'<,'>"
syn match   vimtutorCmd     "\V:'<,'>\a\w*"

" <Enter>, <Tab>, <C-Space>, <Esc>, <CR> ... key notation.
syn region  vimtutorSpecial start='<\h' end='>' oneline

" Control keys called out in words: Ctrl-W, Ctrl-A, Ctrl-\ ...
syn match   vimtutorKeys    '\<Ctrl-\h'
syn match   vimtutorKeys    'Ctrl-\\'

" Admonitions.
syn keyword vimtutorNote    NOTE TIP WARNING REMEMBER
syn keyword vimtutorNote    note tip warning remember

" Table of contents links in the index (|01|) -- <Enter> opens them.
syn match   vimtutorTocLink '|\d\+|'

" Numbered step labels ("1. ", "  2. ").
syn match   vimtutorStep    '^\s\+\d\+\.\s'

" Plain-text URLs.
syn match   vimtutorUrl     '\<https\?://\S\+'

hi def link vimtutorTilde   Comment
hi def link vimtutorBox     Title
hi def link vimtutorTitle   Title
hi def link vimtutorTarget  Todo
hi def link vimtutorCmd     Statement
hi def link vimtutorCmdEx   Statement
hi def link vimtutorSpecial Special
hi def link vimtutorKeys    Question
hi def link vimtutorNote    Todo
hi def link vimtutorTocLink Underlined
hi def link vimtutorStep    Label
hi def link vimtutorUrl     Underlined

let b:current_syntax = 'vimtutor'
