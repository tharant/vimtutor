#!/bin/sh
# ============================================================================
# setup.sh -- VIMTUTOR ADVANCED installer
#
# Designed for the "curl | sh" one-liner AND for running from a checkout:
#
#     curl -fsSL <raw-url-to-setup.sh> | sh
#
# Safe and sane defaults:
#   * never edits your init files without first making a timestamped backup
#   * all of its own edits are marker-guarded and idempotent (re-run freely);
#     --uninstall removes exactly those guarded blocks and nothing else
#   * system package installs are skipped (with the commands printed) rather
#     than guessed at when there is no passwordless sudo
#   * nothing is run inside your editor unless you pass --auto-install-plugins
#
# Usage: sh setup.sh [options]
#   --editor=both|vim|nvim   which editor to install/wire   (default: both)
#   --repo=URL_or_PATH       git URL (or local dir) of the tutor repo
#                            (default: $VIMTUTOR_REPO_URL, else the built-in
#                            URL below).
#   --home=DIR               install root  (default: $VIMTUTOR_HOME, else
#                            ~/.local/share/vimtutor)
#   --refresh                re-copy an EXISTING local --repo install
#                            (deletes the install dir first)
#   --link                   dev helper: symlink a local --repo instead of copy
#   --with-tools             also install fzf + ripgrep when the pkg mgr has them
#   --no-pkg                 never touch system packages (print commands only)
#   --auto-install-plugins   run :PlugInstall --sync right now (network!)
#   --uninstall              remove the vimtutor blocks from your init files
#   --dry-run                print what would happen, change nothing
#   --help                   this text
#
# macOS: uses whichever of Homebrew / MacPorts is installed. With both, it
# picks Homebrew on Apple Silicon and MacPorts on Intel (Homebrew no longer
# supports Intel Macs); VIMTUTOR_MACOS_PKG_MGR=brew|port overrides (the
# dots repo's DOTS_MACOS_PKG_MGR is honored too). It never installs either.
# ============================================================================

set -eu
umask 022

REPO_URL_DEFAULT='https://github.com/tharant/vimtutor'
REPO_URL="${VIMTUTOR_REPO_URL:-$REPO_URL_DEFAULT}"
REPO_ARG=''
HOME_DIR="${VIMTUTOR_HOME:-}"
MODE='both'
WITH_TOOLS=0
NO_PKG=0
AUTO_PLUGINS=0
DRY_RUN=0
UNINSTALL=0
LINK=0
REFRESH=0

BEG='>>> vimtutor >>>'
END='<<< vimtutor <<<'

step()   { printf '== %s\n' "$*"; }
say()    { printf '   %s\n' "$*"; }
warn()   { printf '!! %s\n' "$*" >&2; }
die()    { warn "$*"; exit 1; }
run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    say "(dry-run) $*"
  else
    "$@"
  fi
}

usage() {
  sed -n '3,38p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

# --- arguments ---------------------------------------------------------------

while [ $# -gt 0 ]; do
  case "$1" in
    --editor*) MODE="${1#--editor=}"; [ "$1" = "--editor" ] && { MODE="$2"; shift; } ;;
    --repo*)   REPO_ARG="${1#--repo=}";   [ "$1" = "--repo" ]   && { REPO_ARG="$2"; shift; } ;;
    --home*) HOME_DIR="${1#--home=}"; [ "$1" = "--home" ] && { HOME_DIR="$2"; shift; } ;;
    --link)   LINK=1 ;;
    --refresh) REFRESH=1 ;;
    --with-tools) WITH_TOOLS=1 ;;
    --no-pkg) NO_PKG=1 ;;
    --auto-install-plugins) AUTO_PLUGINS=1 ;;
    --uninstall) UNINSTALL=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --help|-h) usage ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
  shift
done

case "$MODE" in both|vim|nvim) ;; *) die "--editor must be both|vim|nvim" ;; esac

# --- platform ------------------------------------------------------------

OS="$(uname -s)"
case "$OS" in
  Darwin) SYS=macos ;;
  Linux)  SYS=linux ;;
  *) SYS=other ;;
esac

PKG=''
if [ "$SYS" = 'macos' ]; then
  # A curl|sh (or ssh) shell often lacks the managers' bin dirs, so look in
  # their standard prefixes, not just PATH. Homebrew: /opt/homebrew (Apple
  # Silicon) or /usr/local (legacy Intel); MacPorts: /opt/local.
  MAC_BREW=''
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$b" ]; then MAC_BREW="$b"; break; fi
  done
  [ -n "$MAC_BREW" ] || MAC_BREW="$(command -v brew 2>/dev/null || true)"
  MAC_PORT=''
  if [ -x /opt/local/bin/port ]; then MAC_PORT=/opt/local/bin/port
  else MAC_PORT="$(command -v port 2>/dev/null || true)"; fi
  # hw.optional.arm64 is 1 on Apple Silicon even under Rosetta, and an
  # unknown oid on Intel.
  MAC_ARM=0
  [ "$(sysctl -n hw.optional.arm64 2>/dev/null || true)" = '1' ] && MAC_ARM=1

  MAC_PREF="${VIMTUTOR_MACOS_PKG_MGR:-${DOTS_MACOS_PKG_MGR:-}}"
  case "$MAC_PREF" in
    '') ;;
    brew)
      if [ -n "$MAC_BREW" ]; then PKG=brew
      else warn "VIMTUTOR_MACOS_PKG_MGR=brew, but Homebrew is not installed; choosing automatically"; fi ;;
    port)
      if [ -n "$MAC_PORT" ]; then PKG=port
      else warn "VIMTUTOR_MACOS_PKG_MGR=port, but MacPorts is not installed; choosing automatically"; fi ;;
    *) die "VIMTUTOR_MACOS_PKG_MGR must be brew or port (got: $MAC_PREF)" ;;
  esac
  if [ -z "$PKG" ]; then
    if [ -n "$MAC_BREW" ] && [ -n "$MAC_PORT" ]; then
      if [ "$MAC_ARM" -eq 1 ]; then PKG=brew; else PKG=port; fi
    elif [ -n "$MAC_BREW" ]; then PKG=brew
    elif [ -n "$MAC_PORT" ]; then PKG=port
    fi
  fi
  # The chosen manager's bin dir goes first, so editors it installed (or
  # installs below) win over Apple's /usr/bin/vim -- as in an interactive
  # shell set up by its own instructions.
  case "$PKG" in
    brew) PATH="$(dirname "$MAC_BREW"):$PATH" ;;
    port) mac_bin="$(dirname "$MAC_PORT")"; PATH="$mac_bin:${mac_bin%/bin}/sbin:$PATH" ;;
  esac
  export PATH
else
  for m in apt-get dnf yum zypper pacman apk brew; do
    if command -v "$m" >/dev/null 2>&1; then
      case "$m" in
        apt-get) PKG=apt ;;
        *) PKG="$m" ;;
      esac
      break
    fi
  done
fi

# Passwordless privilege escalation, or none (we do NOT prompt in curl|sh).
SUDO=''
NO_PASSWORD=0
if [ "$(id -u)" = '0' ]; then
  SUDO=''
elif command -v sudo >/dev/null 2>&1 && (sudo -n true 2>/dev/null); then
  SUDO='sudo'
else
  NO_PASSWORD=1
fi

pkg_install() {
  # pkg_install <pkg-manager> <name>...
  mgr="$1"; shift
  [ $# -eq 0 ] && return 0
  cmd_args=''
  case "$mgr" in
    apt)   cmd_args='env DEBIAN_FRONTEND=noninteractive apt-get install -y' ;;
    dnf|yum) cmd_args='install -y' ;;
    zypper) cmd_args='--non-interactive install' ;;
    pacman) cmd_args='-S --noconfirm' ;;
    apk)    cmd_args='add' ;;
    brew)   cmd_args='install' ;;
    port)   cmd_args='-N install' ;;
  esac
  case "$mgr" in
    apt|dnf|yum|zypper|port) prefix="$SUDO" ;;
    *) prefix='' ;;  # pacman/apk/brew: root via sudo only when already root
  esac
  if [ "$mgr" = 'pacman' ] && [ -n "$SUDO" ]; then prefix='sudo'; fi
  if [ "$mgr" = 'apk' ] && [ -n "$SUDO" ]; then prefix='sudo'; fi
  if [ "$mgr" != 'brew' ] && [ -z "$prefix" ] && [ "$NO_PASSWORD" -eq 1 ] && [ "$(id -u)" != '0' ] && [ "$mgr" != 'brew' ]; then
    warn "no passwordless root available; run manually: sudo $mgr $cmd_args $*"
    MISSING_SYSTEM=1
    return 0
  fi
  if [ "$mgr" = 'brew' ]; then
    say "brew install $*"
    run brew install "$@"
  else
    say "$prefix $mgr $cmd_args $*"
    if [ "$DRY_RUN" -eq 1 ]; then
      say "(dry-run) skipped"
    elif [ -n "$prefix" ]; then
      # shellcheck disable=SC2086  # cmd_args is one flag-list on purpose
      $prefix "$mgr" $cmd_args "$@"
    else
      # shellcheck disable=SC2086  # cmd_args is one flag-list on purpose
      "$mgr" $cmd_args "$@"
    fi
  fi
}

# per-manager package names
pkg_pkgs() {
  # pkg_pkgs <manager> <generic...>   (echoes real names)
  mgr="$1"; shift
  _out=''
  for p in "$@"; do
    n="$p"
    case "$mgr:$p" in
      *:vim) n='vim' ;;
      *:neovim) n='neovim' ;;
      *:node) n='nodejs' ;;
      *:fzf) n='fzf' ;;
      *:ripgrep) n='ripgrep' ;;
      *:curl) n='curl' ;;
      *:git) n='git' ;;
    esac
    case "$mgr:$p" in
      dnf:vim|yum:vim) n='vim-enhanced' ;;
      brew:node) n='node' ;;
      port:node) n='nodejs24' ;;  # MacPorts only ships versioned node ports
      brew:ripgrep) n='ripgrep' ;;
    esac
    _out="$_out $n"
  done
  printf '%s' "$_out"
}

# --- uninstall ---------------------------------------------------------------

if [ "$UNINSTALL" -eq 1 ]; then
  if [ -z "$HOME_DIR" ]; then
    HOME_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/vimtutor"
  fi
  # Remove guarded blocks from every candidate init file.
  for f in "$HOME/.vimrc" "$HOME/.vim/vimrc" \
           "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/init.vim" \
           "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/init.lua"; do
    if [ -f "$f" ] && grep -qF "$BEG" "$f"; then
      cp "$f" "$f.vimtutor-bak-$(date -u +%Y%m%dT%H%M%SZ)"
      tmpf="$(mktemp)"
      awk "BEGIN{s=0} /$BEG/{s=1; next} /$END/{s=0; next} !s" "$f" > "$tmpf"
      mv "$tmpf" "$f"
      say "removed vimtutor block from $f (backup kept)"
    fi
  done
  if [ -f "$HOME_DIR/doc/tags" ]; then
    run rm -f "$HOME_DIR/doc/tags"
  fi
  say "uninstall done. To delete the clone+plugins entirely:"
  say "  rm -rf '$HOME_DIR'"
  say "Your original init file contents are in the *.vimtutor-bak-* files."
  exit 0
fi

# --- install root ------------------------------------------------------------

if [ -z "$HOME_DIR" ]; then
  HOME_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/vimtutor"
fi
step "install root: $HOME_DIR"
[ "$DRY_RUN" -eq 1 ] && say "(dry-run) nothing below will actually run"

# --- system packages ---------------------------------------------------------

step "checking system dependencies"
say "package manager: ${PKG:-none found}"
have() { command -v "$1" >/dev/null 2>&1; }
MISSING_SYSTEM=0

if [ "$SYS" = 'linux' ] && [ -z "$PKG" ]; then
  warn "no known package manager found (apt/dnf/yum/zypper/pacman/apk)"
  say "install these by hand, then re-run with the editors present:"
  say "  git curl neovim (or vim) node"
  MISSING_SYSTEM=1
fi
if [ "$SYS" = 'macos' ] && [ -z "$PKG" ]; then
  if [ "$MAC_ARM" -eq 1 ]; then
    warn "no package manager found; install Homebrew (https://brew.sh), then re-run"
    say "  brew install git curl neovim vim node"
  else
    warn "no package manager found; Homebrew no longer supports Intel Macs --"
    say "install MacPorts (https://www.macports.org/install.php), then re-run"
    say "  sudo port install git curl neovim vim nodejs24"
  fi
  MISSING_SYSTEM=1
fi

if [ -n "$PKG" ] && [ "$NO_PKG" -eq 0 ]; then
  want=''
  case "$MODE" in
    both) want='neovim vim' ;;
    vim)  want='vim' ;;
    nvim) want='neovim' ;;
  esac
  # Base tools: need git+curl for the clone / plug.vim fetch.
  [ "$REPO_ARG" = "" ] && want="$want git curl"
  if [ "$WITH_TOOLS" -eq 1 ]; then want="$want fzf ripgrep"; fi

  todo=''
  for p in $want; do
    # package 'neovim' provides the binary 'nvim' -- compare binaries
    bin="$p"
    case "$p" in neovim) bin=nvim ;; node) bin=node ;; esac
    have "$bin" || todo="$todo $p"
  done
  if [ -n "$todo" ]; then
    # shellcheck disable=SC2086 disable=SC2046  # both are word lists on purpose
    pkg_install "$PKG" $(pkg_pkgs "$PKG" $todo)
  else
    say "all base packages already present"
  fi
else
  say "package installs skipped (managers/flags), continuing with what exists"
fi

# node quality check for coc.nvim: it needs >= 18 and refuses politely.
if have node; then
  node_major="$(node -e 'process.stdout.write(String(process.versions.node.split(".")[0]))' 2>/dev/null || echo 0)"
  if [ "${node_major:-0}" -lt 18 ]; then
    warn "node $(node -v 2>/dev/null) found but coc.nvim needs >= 18;"
    say "completion will stay off until you update node, then re-run :PlugStatus"
  fi
else
  warn "node missing: coc.nvim (completion/LSP) cannot run without it."
  case "$PKG" in
    port) say "install node >= 18 (e.g. sudo port install nodejs24), then re-run setup." ;;
    brew) say "install node >= 18 (e.g. brew install node), then re-run setup." ;;
    *)    say "install node >= 18 (e.g. from nodejs.org or your distro), then re-run setup." ;;
  esac
fi

# Editors present? (after installs)
VIM_BIN="$(command -v vim 2>/dev/null || true)"
NVIM_BIN="$(command -v nvim 2>/dev/null || true)"

case "$MODE" in
  vim)  [ -n "$VIM_BIN" ]  || die "vim not found and --editor=vim was requested" ;;
  nvim) [ -n "$NVIM_BIN" ] || die "neovim not found and --editor=nvim was requested" ;;
  both) [ -n "$VIM_BIN" ] || [ -n "$NVIM_BIN" ] || die "neither vim nor neovim found" ;;
esac

# Debian/Ubuntu's plain vim lacks some coc prerequisites; steer clearly.
if [ -n "$VIM_BIN" ]; then
  if ! "$VIM_BIN" --version 2>/dev/null | grep -q '+channel'; then
    warn "your vim lacks +channel/+job; coc.nvim will not run in it."
    [ "$PKG" = 'apt' ] && say "consider: sudo apt install vim-gtk3 (this brings a full-featured /usr/bin/vim)"
  fi
  if ! "$VIM_BIN" --version 2>/dev/null | grep -q '+clipboard'; then
    say "note: your vim lacks +clipboard (system-clipboard registers)."
    say "      Debian/Ubuntu: vim-gtk3 package restores it; Neovim needs xclip/wl-clipboard."
  fi
fi

# --- fetch the tutor runtime ---------------------------------------------------

step "installing the tutor runtime tree"
# State of $HOME_DIR: absent, empty-but-usable, a vimtutor install, or junk.
IS_VALID=0
if [ -f "$HOME_DIR/plugin/vimtutor.vim" ]; then
  IS_VALID=1
elif [ -e "$HOME_DIR" ] && [ -z "$(ls -A "$HOME_DIR" 2>/dev/null)" ]; then
  run rmdir "$HOME_DIR"; IS_VALID=0
elif [ -e "$HOME_DIR" ]; then
  die "$HOME_DIR exists but is not a vimtutor install; choose another with --home=..."
fi

copy_fresh() {  # copy the working tree, excluding .git
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$HOME_DIR"
  fi
  if command -v tar >/dev/null 2>&1; then
    say "tar copy into $HOME_DIR (working tree, without .git)"
    if [ "$DRY_RUN" -eq 0 ]; then
      tar -C "$REPO_ARG" --exclude=./.git --exclude=.git -cf - . \
        | tar -xf - -C "$HOME_DIR"
    else
      say "(dry-run) skipped"
    fi
    return 0
  fi
  run cp -a "$REPO_ARG/." "$HOME_DIR/"
}

fetch_from_local() {
  if [ ! -d "$REPO_ARG" ]; then die "--repo path '$REPO_ARG' is not a directory"; fi
  if [ ! -f "$REPO_ARG/plugin/vimtutor.vim" ]; then
    die "--repo path '$REPO_ARG' does not look like the vimtutor repo"
  fi
  if [ "$LINK" -eq 1 ] && [ ! -e "$HOME_DIR" ]; then
    say "symlink $HOME_DIR -> $REPO_ARG"
    run ln -sfn "$REPO_ARG" "$HOME_DIR"
  else
    copy_fresh
  fi
}

fetch_from_git() {
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$(dirname "$HOME_DIR")"
  fi
  run git clone --depth=1 "$REPO_URL" "$HOME_DIR"
}

if [ "$IS_VALID" -eq 1 ]; then
  if [ "$REFRESH" -eq 1 ] && [ "$REPO_ARG" != '' ]; then
    warn "--refresh: replacing the existing install at $HOME_DIR"
    run rm -rf "$HOME_DIR"
    fetch_from_local
  elif [ "$REPO_ARG" = '' ]; then
    say "existing install found; updating from git (fast-forward only)"
    if [ "$DRY_RUN" -eq 1 ]; then
      say "(dry-run) git update skipped"
    elif [ ! -d "$HOME_DIR/.git" ]; then
      say "install is not a git checkout, left as is"
    elif git -C "$HOME_DIR" fetch --quiet 2>/dev/null; then
      git -C "$HOME_DIR" reset --hard --quiet origin/HEAD 2>/dev/null
      say "updated install from origin"
    else
      warn "git fetch failed (offline?); keeping the existing install"
    fi
  else
    say "existing install at $HOME_DIR, left as is (--refresh re-copies)"
  fi
elif [ "$REPO_ARG" != '' ]; then
  fetch_from_local
else
  fetch_from_git
fi
command -v git >/dev/null 2>&1 || warn "git not available; use --repo with a local directory"

# --- vim-plug bootstrap -------------------------------------------------------

step "fetching vim-plug (the in-editor plugin manager)"
run mkdir -p "$HOME_DIR/autoload"
PLUG_TARGET="$HOME_DIR/autoload/plug.vim"
if [ -f "$PLUG_TARGET" ]; then
  say "plug.vim already present"
else
  if ! run curl -fsSL --proto '=https' --tlsv1.2 --retry 2 \
        -o "$PLUG_TARGET" \
        'https://raw.githubusercontent.com/junegunn/vim-plug/HEAD/plug.vim'; then
    if [ ! -f "$PLUG_TARGET" ]; then
      warn "could not download plug.vim; plugins stay OFF until you re-run setup.sh"
    fi
  fi
fi

# --- wire editor configs -------------------------------------------------------

wire_vim_file() {  # wire_vim_file <path> <fresh>
  f="$1"
  if grep -qF "$BEG" "$f" 2>/dev/null; then
    say "already wired: $f"
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    say "(dry-run) would back up and append the vimtutor block to: $f"
    return 0
  fi
  if [ "$2" != 'fresh' ]; then
    cp "$f" "$f.vimtutor-bak-$(date -u +%Y%m%dT%H%M%SZ)"
    say "backed up original to $(basename "$f").vimtutor-bak-*"
  fi
  tmpf="$(mktemp)"
  {
    sed "s|__VIMTUTOR_HOME__|$HOME_DIR|g" <<'VIMEOF'

" >>> vimtutor >>> (managed block; removed by setup.sh --uninstall)
let g:vimtutor_data = '__VIMTUTOR_HOME__'
if filereadable('__VIMTUTOR_HOME__/config/vimrc.common')
  source __VIMTUTOR_HOME__/config/vimrc.common
else
  echom 'vimtutor: missing __VIMTUTOR_HOME__ -- re-run setup.sh'
endif
" <<< vimtutor <<<
VIMEOF
  } >> "$tmpf"
  if [ "$2" != 'fresh' ]; then cat "$f" >> "$tmpf"; fi
  mv "$tmpf" "$f"
  say "wired: $f"
}

wire_lua_file() {  # wire_lua_file <path> <fresh>
  f="$1"
  if grep -qF "$BEG" "$f" 2>/dev/null; then
    say "already wired: $f"
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    say "(dry-run) would back up and append the vimtutor block to: $f"
    return 0
  fi
  tmpf="$(mktemp)"
  {
    sed "s|__VIMTUTOR_HOME__|$HOME_DIR|g" <<'LUAEOF'

-- >>> vimtutor >>> (managed block; removed by setup.sh --uninstall)
local vimtutor_ok, vimtutor_err = pcall(vim.cmd,
  "let g:vimtutor_data = '__VIMTUTOR_HOME__'")
if vimtutor_ok then
  vimtutor_ok, vimtutor_err =
    pcall(vim.cmd, "source __VIMTUTOR_HOME__/config/vimrc.common")
end
if not vimtutor_ok then
  vim.notify("vimtutor: setup incomplete (" .. tostring(vimtutor_err)
    .. ") -- re-run setup.sh", vim.log.levels.WARN)
end
-- <<< vimtutor <<<
LUAEOF
  } >> "$tmpf"
  if [ "$2" != 'fresh' ]; then cat "$f" >> "$tmpf"; fi
  mv "$tmpf" "$f"
  say "wired: $f"
}

step "wiring editor init files"
VIMRC_WIRED=''
NVIMRC_WIRED=''

if [ -n "$VIM_BIN" ] || [ "$MODE" != 'nvim' ]; then
  if [ "$MODE" = 'vim' ] || [ "$MODE" = 'both' ]; then
    if [ -f "$HOME/.vimrc" ]; then
      wire_vim_file "$HOME/.vimrc" existing
    elif [ -f "$HOME/.vim/vimrc" ]; then
      wire_vim_file "$HOME/.vim/vimrc" existing
    else
      run touch "$HOME/.vimrc"
      wire_vim_file "$HOME/.vimrc" fresh
    fi
    VIMRC_WIRED=1
  fi
fi

if [ "$MODE" = 'nvim' ] || [ "$MODE" = 'both' ]; then
  cfgdir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
  run mkdir -p "$cfgdir"
  if [ -f "$cfgdir/init.lua" ]; then
    # Neovim reads init.lua INSTEAD of init.vim -- wire into the lua file.
    wire_lua_file "$cfgdir/init.lua" existing
    NVIMRC_WIRED="$cfgdir/init.lua"
  elif [ -f "$cfgdir/init.vim" ]; then
    wire_vim_file "$cfgdir/init.vim" existing
    NVIMRC_WIRED="$cfgdir/init.vim"
  else
    if [ "$DRY_RUN" -eq 0 ]; then
      echo '" created by vimtutor setup.sh' > "$cfgdir/init.vim"
    fi
    wire_vim_file "$cfgdir/init.vim" existing
    NVIMRC_WIRED="$cfgdir/init.vim"
  fi
fi

# --- help tags ----------------------------------------------------------------

step "building help tags"
if [ -n "$NVIM_BIN" ]; then
  run "$NVIM_BIN" --headless -u NONE "+helptags $HOME_DIR/doc" "+qa"
elif [ -n "$VIM_BIN" ]; then
  run "$VIM_BIN" -u NONE -N -es "+helptags $HOME_DIR/doc" +qa
fi

# --- optional: run the plugin install now --------------------------------------

if [ "$AUTO_PLUGINS" -eq 1 ]; then
  step "installing plugins headlessly (this can take a minute)"
  rcpath="$HOME/.vimrc"
  [ -f "$HOME/.vim/vimrc" ] && ! [ -f "$HOME/.vimrc" ] && rcpath="$HOME/.vim/vimrc"
  if [ -n "$NVIMRC_WIRED" ]; then rcpath="$NVIMRC_WIRED"; fi
  if [ "$SYS" != 'macos' ] && command -v timeout >/dev/null 2>&1; then
    PREF='timeout 900'; else PREF=''; fi
  if [ -n "$NVIM_BIN" ]; then
    EDITOR_BIN="$NVIM_BIN"
  elif [ -n "$VIM_BIN" ]; then
    EDITOR_BIN="$VIM_BIN"
  fi
  say "running: $PREF $EDITOR_BIN -u $rcpath +PlugInstall"
  if [ "$DRY_RUN" -eq 0 ]; then
    $PREF "$EDITOR_BIN" -u "$rcpath" \
      "+silent! PlugInstall --sync" "+qa" || warn "plugin install had trouble; re-run :PlugInstall manually"
    # a second launch lets coc bootstrap its extensions (needs node)
    if have node; then
      say "bootstrapping coc extensions"
      $PREF "$EDITOR_BIN" -u "$rcpath" "+qa" || true
    fi
  fi
fi

# --- summary -------------------------------------------------------------------

step "done"
say "config wired:"
if [ -n "$VIMRC_WIRED" ]; then
  if [ -f "$HOME/.vimrc" ]; then
    say "  vim:    $HOME/.vimrc"
  else
    say "  vim:    $HOME/.vim/vimrc"
  fi
fi
[ -n "$NVIMRC_WIRED" ] && say "  neovim: $NVIMRC_WIRED"
if [ "$MISSING_SYSTEM" -eq 1 ]; then
  warn "some system packages were NOT installed (see the !! lines above)."
  say "install them, then re-run setup.sh --editor=$MODE to finish."
fi
if [ "$AUTO_PLUGINS" -eq 1 ]; then
  say "  1. language servers you want:"
  say "       :CocInstall coc-json coc-tsserver      (js/ts; json)"
  say "       :CocInstall coc-pyright coc-clangd     (python; c/c++)"
  say "  2. start:  :Tutor"
else
  say "  1. open your editor and run  :PlugInstall"
  say "  2. language servers you want:"
  say "       :CocInstall coc-json coc-tsserver      (js/ts; json)"
  say "       :CocInstall coc-pyright coc-clangd     (python; c/c++)"
  say "  3. start:  :Tutor"
fi
exit 0
