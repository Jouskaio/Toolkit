#!/bin/bash

# Runs every *.test.sh of the toolkit and prints a summary; the exit code is the number of failing files.
# Run with: bash tests/run-all.sh   (or: toolkit test)

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failed=0
count=0
for test in "$ROOT"/*/tests/*.test.sh "$ROOT"/tests/*.test.sh; do
  [ -f "$test" ] || continue
  count=$((count + 1))
  name="${test#"$ROOT"/}"
  if output=$(bash "$test" 2>&1); then
    echo "PASS $name ($(echo "$output" | grep -c '^ok '))"
  else
    echo "FAIL $name"
    echo "$output" | grep '^FAIL' | sed 's/^/     /'
    failed=$((failed + 1))
  fi
done
echo
echo "$((count - failed))/$count test files passed."
exit "$failed"
