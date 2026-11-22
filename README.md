# VIMTUTOR ADVANCED

An advanced, modern remake of the classic `vimtutor` — same tilde-bordered,
learn-by-editing format you remember, but teaching the serious stuff: split
windows, the buffer/window/tab model, registers, macros, text objects,
quickfix, folds, marks, a fully configured editor (`coc.nvim` completion and
LSP, syntax highlighting, status line, colorschemes, git) — and it works
identically in **Vim 9+** and **Neovim 0.10+**.

Everything is learned interactively: every lesson opens as a **scratch copy**
(exactly like the original tutor), so you edit the real thing and throw your
practice changes away by exiting with `:q!`.

**Prerequisite:** you already know the basics (`h j k l`, `i a o`, `x dd u`,
`/pattern`, `:w :q`). If not, run the classic `vimtutor` once first.

## Quick start (`curl | sh`)

```bash
curl -fsSL https://raw.githubusercontent.com/tharant/vimtutor/main/setup.sh | sh
```

Then in your editor:

```vim
:PlugInstall     " once, to install the plugins
:Tutor           " start at the table of contents
```

> One-liners point at `tharant/vimtutor`; if you fork, adjust the two URLs
> (the constant in `setup.sh` and the paths above) to your own slug.

## What `setup.sh` does (and deliberately does not do)

Runs on Linux (apt, dnf/yum, zypper, pacman, apk) and macOS (Homebrew):

1. **Installs missing system packages** — `neovim` and/or `vim` (your choice,
   default both), plus `git`/`curl`. Skipped gracefully — with the exact
   commands printed for you to run — when there is no passwordless root
   (`sudo -n`). Opt in `fzf` + `ripgrep` with `--with-tools`.
2. **Checks Node.js** (≥ 18) — `coc.nvim` needs it; you get a pointed warning
   either way (no surprise third-party repositories are ever added).
3. **Installs the tutor runtime** into `~/.local/share/vimtutor` (override
   with `--home=` or `$VIMTUTOR_HOME`) — the lessons, the plugin, the shared
   configuration. Nothing outside that directory plus your init file changes.
4. **Downloads `plug.vim`** (vim-plug) so plugin management stays **in the
   editor** — `:PlugInstall` / `:PlugUpdate` / `:PlugClean`, no shell scripts.
5. **Wires your init file** — prepends a marker-guarded block to
   `~/.vimrc` (or `~/.vim/vimrc`) and to Neovim's
   `~/.config/nvim/init.vim` **or** `init.lua` (whichever exists; block goes
   in front of your code so user overrides always win). It never overwrites:
   originals are backed up next to the file as `*.vimtutor-bak-*.`.
6. **Builds the help tags** so `:help vimtutor` works.
7. Prints next steps. It does **not** launch your editor or touch plugins
   unless you pass `--auto-install-plugins`.

The block it appends looks like this and is idempotent — re-running
`setup.sh` is always safe:

```vim
" >>> vimtutor >>> (managed block; removed by setup.sh --uninstall)
let g:vimtutor_data = '~/.local/share/vimtutor'
if filereadable('~/.local/share/vimtutor/config/vimrc.common')
  source ~/.local/share/vimtutor/config/vimrc.common
else
  echom 'vimtutor: missing ~/.local/share/vimtutor -- re-run setup.sh'
endif
" <<< vimtutor <<<
```

### Flags

| Flag | Meaning |
|------|---------|
| `--editor=both\|vim\|nvim` | which editor(s) to install/wire (default: both) |
| `--repo=URL_or_DIR` | install from this git URL or local checkout instead |
| `--home=DIR` | install root (default `~/.local/share/vimtutor`) |
| `--link` | dev helper: symlink a local `--repo` instead of copying |
| `--refresh` | re-copy an existing local `--repo` install (deletes it first) |
| `--with-tools` | also install `fzf` + `ripgrep` when available |
| `--no-pkg` | never touch system packages, print commands instead |
| `--auto-install-plugins` | run `:PlugInstall --sync` headlessly right now |
| `--uninstall` | remove both managed blocks (keeps backups + the clone; it prints one `rm -rf` for that) |

## Manual install (no `curl | sh`)

```bash
git clone https://github.com/tharant/vimtutor.git
cd vimtutor
sh setup.sh --repo "$(pwd)"          # everything, from the local checkout
# or just print the plan first:
sh setup.sh --repo "$(pwd)" --dry-run
```

Fully manual wiring, if you would rather not run the script: clone the repo
anywhere, make sure `set runtimepath^=/path/to/vimtutor` lands early in your
init file (before plugin loading), then source `config/vimrc.common`:

```vim
set runtimepath^=~/.local/share/vimtutor
let g:vimtutor_data = '~/.local/share/vimtutor'
source ~/.local/share/vimtutor/config/vimrc.common
```

## Using the tutor

```vim
:Tutor            " table of contents (press <Enter> on a |01| entry)
:Tutor 3          " jump straight to lesson 3 (accepts 03 too)
:Tutor splits     " or any name fragment; Tab completes
:TutorClassic     " the stock markdown tutorial that ships with the editor
:help vimtutor    " the reference
```

| # | Lesson |
|---|--------|
| 01 | Windows and splits |
| 02 | Buffers and tabs — the mental model |
| 03 | Registers beyond basics (`"0`, named, blackhole, clipboards) |
| 04 | Macros: recorded power |
| 05 | Visual modes and text objects (incl. block mode, surround) |
| 06 | Search, `:s` flags, very magic, `:global`, quickfix across files |
| 07 | Marks and the jumplist (plus the `q:` command window) |
| 08 | Folds |
| 09 | Your config: mappings, plugins, colorschemes (guided tour) |
| 10 | Files, `:args`, sessions, netrw |
| 11 | Terminals (`:term`) and git (fugitive) |
| 12 | Completion and LSP with `coc.nvim` |
| 13 | Cheat sheet: everything on one page |

Lessons are single files under `lessons/`; the scratch copies (including
`lessons/demo/*.js|.c|.py` practice targets) live in a temp folder per
session, and the lesson window's working directory is that folder, so
`:e`, `:find`, `:vimgrep **/*`, and netrw all operate inside the sandbox.

## The configuration that ships

`config/vimrc.common` is the single source shared by both editors. It degrades
gracefully: **all plugin blocks are guarded**, so before `:PlugInstall` you
get a clean, sane vanilla editor, and afterward the full experience.

| Feature | Vim 9 | Neovim 0.10 |
|---|---|---|
| completion + LSP | coc.nvim | coc.nvim *(same keys)* |
| syntax highlighting | vim-polyglot | nvim-treesitter |
| status line | vim-airline | lualine.nvim |
| colorschemes | gruvbox | gruvbox + tokyonight |
| git | fugitive | fugitive |
| fuzzy finder | fzf.vim (if `fzf` binary) | fzf.vim (if `fzf` binary) |
| small QoL | commentary, surround, sleuth | same |

Opinionated defaults worth knowing (change them in `~/.local/share/vimtutor/config/vimrc.common`
or, better, override in your init file, which is sourced first for
Neovim/after for Vim — your file always wins):

- `<leader>` is the **space bar**; `<space>w` writes, `<space>v`/`<space>s`
  split, `<space>t` tab-new, `<space>bl` `:ls`, `<space>h` clears search, …
- `hidden`, `splitbelow splitright`, `number relativenumber`, `scrolloff=8`,
  `ignorecase smartcase`, `wildmenu`, `path+=**`, persistent undo.
- coc keys (when coc is installed): `gd gy gi gr`, `[g ]g`, `K`,
  `<leader>rn` rename, `<leader>ac` code action, `<leader>qf` quickfix,
  `<leader>f` format selection; Tab accepts completions, `Ctrl-Space` triggers.
- `:Theme gruvbox` switches colorschemes (`:Theme name!` persists the choice
  by rewriting the default inside the shared config).
- The system clipboard is deliberately **not** merged with `"` — lesson 03
  explains the tradeoff and how to flip it (`:set clipboard=unnamed`).

## Vim vs Neovim notes

- The tutor behaves identically in both. It shadows the built-in `:Tutor`
  command on purpose; `:TutorClassic` gets you the editor's stock interactive
  tutorial back.
- Neovim needs nothing extra for the `+`/`*` registers beyond a provider
  (`xclip`, `wl-clipboard`, `pbcopy`) — run `:checkhealth` to see. Vim needs a
  build **with** `+clipboard`: Debian/Ubuntu's default `vim` package lacks it;
  `sudo apt install vim-gtk3` fixes both that and `:term` niceties. `setup.sh`
  prints this for you if it detects the deficiency.
- `nvim-treesitter` builds parsers at install time, so have a C compiler
  (`gcc`/`clang`) around on Neovim — the polyglot path on Vim needs none.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `:Tutor` says no lessons found | the install tree moved — re-run `setup.sh` (it only rewrites its managed block) |
| no completion menus in lesson 12 | `:CocInfo` + node ≥ 18? then `:CocInstall coc-tsserver` |
| vim `E319`/feature complaints from coc | your vim lacks `+channel` — switch to Neovim or a fuller vim build (`vim-gtk3`) |
| colors look wrong over SSH | `export COLORTERM=truecolor` before launching, or pick gruvbox |
| want the old tutor exactly | `:TutorClassic` here, or plain `vimtutor` in a shell |

## For developers

- Lesson content is plain text in `lessons/`; the tutor format is the classic
  `~`-bordered style with `--->` practice targets. Run `sh test/run.sh` after
  any content or plugin change — it executes the headless smoke suite under
  both editors plus lesson integrity checks (link table, line widths, tabs).
- `setup.sh` is POSIX `sh`, `shellcheck`-clean, and fully tested in an
  isolated `HOME` (`test/config_check.sh`).
- Before publishing, replace `YOUR-GITHUB-USERNAME` in `setup.sh` (one
  constant) and in the README, push, and the `curl -fsSL .../setup.sh | sh`
  one-liner above becomes live.
- The committed agent log contains no personal data by construction: it is
  scrubbed through the local, gitignored `.agentlog-redactions` map on
  every export (see `AGENTS.md`). Keep your map out of the repo; if a
  future output reveals a new pattern, extend the map and regenerate
  (`scripts/export-agent-log`) before committing. For a fresh fork: copy
  `.agentlog-redactions.example`, fill in your values, then run the
  exporter once before the first public commit.

## Agent session log

Every commit in this repository carries the full agentic development log
(user prompts, model reasoning, tool calls with input/output) under
`agentlog/`. It is maintained by `scripts/export-agent-log` and a
pre-commit hook (`.githooks/`, `core.hooksPath`); the rule lives in
`AGENTS.md` and the browsable index in `agentlog/README.md`.

## License

MIT (the lessons and tooling of this repository; the plugin libraries it
installs keep their own licenses).
