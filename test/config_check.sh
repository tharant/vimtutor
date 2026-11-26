#!/bin/sh
# Exercise config/vimrc.common in both editors with NO plugins, inside an
# isolated HOME, and verify the "degraded but sane" path.
set -eu

cd "$(dirname "$0")/.."
repo=$(pwd)
tmp=$(mktemp -d)
log=$(mktemp /tmp/vimtutor-config.XXXXXX.log)
trap 'rm -rf "$tmp" "$log"' EXIT
rc=0

# A fake `setup.sh --with-scala` result: a Coursier bin dir with a stub
# metals launcher, plus a fetched JDK recorded in scala/java-home.
mkdir -p "$tmp/vimtutordata/scala/bin" "$tmp/fakejdk/bin"
printf '#!/bin/sh\nexit 0\n' > "$tmp/vimtutordata/scala/bin/metals"
chmod +x "$tmp/vimtutordata/scala/bin/metals"
printf '%s\n' "$tmp/fakejdk" > "$tmp/vimtutordata/scala/java-home"

# The generated rc shape: point at a data dir, then source the common file.
cat > "$tmp/rc.vim" <<EOF
let g:vimtutor_data = '$tmp/vimtutordata'
source $repo/config/vimrc.common
EOF

run_editor() {
  editor=$1
  shift
  : > "$log"
  VIMTUTOR_TEST_REPO="$repo" VIMTUTOR_TEST_LOG="$log" HOME="$tmp" \
    VIMTUTOR_TEST_JDK="$tmp/fakejdk" "$@" \
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
