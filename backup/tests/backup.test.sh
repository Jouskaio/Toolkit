#!/bin/bash

# Checks of lib/backup.sh on temporary folders (nothing outside them is read or written).
# Run with: bash backup/tests/backup.test.sh

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
source "$DIR/../lib/backup.sh"

failures=0
pass() { echo "ok   $1"; }
fail() { echo "FAIL $1"; failures=$((failures + 1)); }
succeeds() { local label="$1"; shift; if "$@" > /dev/null 2>&1; then pass "$label"; else fail "$label"; fi; }
refuses() { local label="$1"; shift; if "$@" > /dev/null 2>&1; then fail "$label"; else pass "$label"; fi; }
equals() { if [ "$2" == "$3" ]; then pass "$1"; else fail "$1 (got '$2', expected '$3')"; fi; }

SRC="$TMP/src"
mkdir -p "$SRC/site" "$SRC/site/node_modules"
echo "page" > "$SRC/site/index.html"
echo "big" > "$SRC/site/data.txt"
echo "dep" > "$SRC/site/node_modules/dep.js"

write_conf() { # keep
  cat > "$TMP/backup.conf" << CONF
SOURCES="$SRC/site"
DEST="$TMP/dest"
KEEP=$1
EXCLUDE="node_modules"
CONF
}

# Config
refuses "a missing config" backup_load "$TMP/none.conf"
echo 'SOURCES=""' > "$TMP/bad.conf"
refuses "empty sources" backup_load "$TMP/bad.conf"
printf 'SOURCES="relative/path"\nDEST="/x"\n' > "$TMP/bad.conf"
refuses "a relative source" backup_load "$TMP/bad.conf"
printf 'SOURCES="/tmp"\nDEST="/x"\nKEEP=0\n' > "$TMP/bad.conf"
refuses "KEEP below 1" backup_load "$TMP/bad.conf"
write_conf 2
succeeds "a valid config" backup_load "$TMP/backup.conf"

# Snapshots
BACKUP_NOW=2026-01-01_100000 backup_run > /dev/null
equals "the first snapshot has the files with their full path" "$(cat "$TMP/dest/2026-01-01_100000$SRC/site/index.html")" "page"
if [ ! -e "$TMP/dest/2026-01-01_100000$SRC/site/node_modules" ]; then pass "excluded folders are not saved"; else fail "excluded folders are not saved"; fi

echo "changed" > "$SRC/site/data.txt"
BACKUP_NOW=2026-01-02_100000 backup_run > /dev/null
a=$(ls -i "$TMP/dest/2026-01-01_100000$SRC/site/index.html" | cut -d' ' -f1)
b=$(ls -i "$TMP/dest/2026-01-02_100000$SRC/site/index.html" | cut -d' ' -f1)
equals "an unchanged file is a hard link to the previous snapshot" "$b" "$a"
equals "a changed file is saved again" "$(cat "$TMP/dest/2026-01-02_100000$SRC/site/data.txt")" "changed"
equals "the first snapshot keeps the old content" "$(cat "$TMP/dest/2026-01-01_100000$SRC/site/data.txt")" "big"

# Rotation
BACKUP_NOW=2026-01-03_100000 backup_run > /dev/null
equals "only KEEP snapshots are left" "$(backup_snapshots | tr '\n' ' ')" "2026-01-02_100000 2026-01-03_100000 "
equals "the list shows them" "$(backup_list | wc -l | tr -d ' ')" "2"

# Failure: a missing source saves nothing
printf 'SOURCES="%s/gone"\nDEST="%s/dest"\nKEEP=2\n' "$SRC" "$TMP" > "$TMP/gone.conf"
backup_load "$TMP/gone.conf"
refuses "a missing source fails" env BACKUP_NOW=2026-01-04_100000 bash -c "source '$DIR/../lib/backup.sh'; backup_load '$TMP/gone.conf'; backup_run"
equals "a failed run leaves no incomplete snapshot" "$(backup_snapshots | tr '\n' ' ')" "2026-01-02_100000 2026-01-03_100000 "

# Dry run and remote
backup_load "$TMP/backup.conf"
out=$(BACKUP_DRY_RUN=1 BACKUP_NOW=2026-01-05_100000 backup_run)
equals "the dry run prints the command and saves nothing" "$(echo "$out" | cut -c1-8) $(backup_snapshots | wc -l | tr -d ' ')" "+ rsync  2"
printf 'SOURCES="%s/site"\nDEST="me@host:/backups/x"\nKEEP=3\nRSYNC_SSH="ssh -p 2222"\n' "$SRC" > "$TMP/remote.conf"
backup_load "$TMP/remote.conf"
out=$(BACKUP_DRY_RUN=1 BACKUP_NOW=2026-01-05_100000 backup_run)
case "$out" in *"-e ssh -p 2222"*"me@host:/backups/x/2026-01-05_100000/"*) pass "a remote destination goes through ssh" ;; *) fail "remote command: $out" ;; esac

echo
if [ "$failures" -eq 0 ]; then echo "All checks passed."; else echo "$failures check(s) failed."; fi
exit "$failures"
