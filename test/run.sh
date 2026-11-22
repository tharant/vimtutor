#!/bin/sh
# Run the smoke tests and lesson-integrity checks under both editors.
#
#   sh test/run.sh            # vim + nvim + lessons
#   sh test/run.sh vim        # only vim
#   sh test/run.sh nvim       # only neovim
set -eu

cd "$(dirname "$0")/.."
repo=$(pwd)
targets=${1:-all}
log=$(mktemp /tmp/vimtutor-smoke.XXXXXX.log)
trap 'rm -f "$log"' EXIT
rc=0

run_editor() {
  editor=$1
  shift
  : > "$log"
  # A custom -u rc (test/mini.vim) is required: -u NONE would skip
  # plugin loading outright, and +args run after the plugin phase.
  VIMTUTOR_TEST_LOG="$log" "$@" \
    -u "$repo/test/mini.vim" '+source test/smoke.vim' '+qa!' 2>&1 | tail -3
  if ! grep -q '== SMOKE OK ==' "$log"; then
    echo "-- $editor smoke FAILED; full log: --"
    cat "$log"
    rc=1
  fi
}

case "$targets" in
  all|vim)
    command -v vim >/dev/null 2>&1 && { echo "== vim smoke =="; run_editor vim vim -N -es -i NONE; } || echo "skip: no vim"
    ;;
esac
case "$targets" in
  all|nvim)
    command -v nvim >/dev/null 2>&1 && { echo "== nvim smoke =="; run_editor nvim nvim --headless -i NONE; } || echo "skip: no nvim"
    ;;
esac

sh test/lessons_check.sh || rc=1
exit "$rc"
