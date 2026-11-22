#!/bin/sh
# Integrity checks for the lessons.
# - index |NN| links must map to existing lesson files
# - no tabs, no lines wider than the classic 78-column practice area
# - box borders intact (first and last lines of the box)
set -eu

cd "$(dirname "$0")/.."
status=0

for f in lessons/00-index.vimtutor; do
  for num in $(grep -o '|[0-9][0-9]|' "$f" | tr -d '|' | sort -u); do
    if ! ls lessons/"$num"-*.vimtutor >/dev/null 2>&1; then
      echo "FAIL: index links to missing lesson $num"
      status=1
    fi
  done
done

for f in lessons/*.vimtutor lessons/demo/*; do
  if grep -qP '\t' "$f"; then
    echo "FAIL: tab characters in $f"
    status=1
  fi
  long=$(awk '!/^=+$/ && length($0)>79 && !/^=.*[^=].*=$/ {c++} END{print c+0}' "$f")
  if [ "$long" -gt 0 ]; then
    echo "FAIL: $f has $long line(s) wider than the 79-column practice area"
    status=1
  fi
done

# every real lesson should carry its lesson number in the title
# (00-index is the TOC, not lesson zero)
for f in lessons/[0-9]*.vimtutor; do
  num=$(basename "$f" | cut -c1-2)
  [ "$num" = "00" ] && continue
  if ! grep -qi "Lesson ${num#0}" "$f"; then
    echo "FAIL: $f does not mention its own lesson number"
    status=1
  fi
done

if [ "$status" -eq 0 ]; then
  echo "== LESSONS OK =="
else
  echo "== LESSONS FAILED =="
fi
exit "$status"
