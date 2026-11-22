#!/bin/sh
# Exercise config/vimrc.common in both editors with NO plugins, inside an
# isolated HOME, and verify the "degraded but sane" path.
set -eu

cd "$(dirname "$0")/.."
repo=$(pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
log=$(mktemp /tmp/vimtutor-config.XXXXXX.log)
trap 'rm -f "$log"' EXIT
rc=0

# The generated rc shape: point at a data dir, then source the common file.
cat > "$tmp/rc.vim" <<EOF
let g:vimtutor_data = '$tmp/vimtutordata'
source $repo/config/vimrc.common
EOF

run_editor() {
  editor=$1
  shift
  : > "$log"
  VIMTUTOR_TEST_REPO="$repo" VIMTUTOR_TEST_LOG="$log" HOME="$tmp" "$@" \
    -u "$tmp/rc.vim" "+source $repo/test/config_check.vim" "+qa!" 2>&1 | tail -3
  if ! grep -q '== CONFIG OK ==' "$log"; then
    echo "-- $editor config check FAILED; log: --"
    cat "$log"
    rc=1
  fi
}

echo "== vim config check =="
run_editor vim vim -N -es -i NONE
echo "== nvim config check =="
run_editor nvim nvim --headless -i NONE
exit "$rc"
