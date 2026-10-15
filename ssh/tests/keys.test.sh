#!/bin/bash

# Checks of lib/keys.sh on a temporary file (your keys.json is never touched).
# Run with: bash ssh/tests/keys.test.sh

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYS_FILE="$(mktemp)"
trap 'rm -f "$KEYS_FILE" "$KEYS_FILE.bak" "$KEYS_FILE.tmp"' EXIT
echo '[]' > "$KEYS_FILE"
source "$DIR/../lib/keys.sh"

failures=0
pass() { echo "ok   $1"; }
fail() { echo "FAIL $1"; failures=$((failures + 1)); }
succeeds() { local label="$1"; shift; if "$@" > /dev/null 2>&1; then pass "$label"; else fail "$label"; fi; }
refuses() { local label="$1"; shift; if "$@" > /dev/null 2>&1; then fail "$label"; else pass "$label"; fi; }
equals() { if [ "$2" == "$3" ]; then pass "$1"; else fail "$1 (got '$2', expected '$3')"; fi; }

succeeds "add a connection with a key" keys_add web id_ed25519 server.example.com deploy ""
succeeds "add a connection with a password and a port" keys_add legacy "" 192.0.2.10 admin 2222
equals "two connections" "$(keys_count)" "2"
equals "key is stored" "$(keys_field 0 key)" "id_ed25519"
equals "empty port becomes null" "$(keys_field 0 port)" ""
equals "empty key becomes null" "$(keys_field 1 key)" ""
equals "port is stored" "$(keys_field 1 port)" "2222"

refuses "duplicate name" keys_add web "" other.example.com me ""
refuses "name with a space" keys_add "my server" "" host.example.com me ""
refuses "port out of range" keys_add big "" host.example.com me 70000
refuses "port that is not a number" keys_add nan "" host.example.com me abc
refuses "missing hostname" keys_add nohost "" "" me ""
equals "refused additions change nothing" "$(keys_count)" "2"

succeeds "edit a connection" keys_update 0 web id_ed25519 new.example.com deploy 22
equals "hostname updated" "$(keys_field 0 hostname)" "new.example.com"
succeeds "keep the same name when editing" keys_update 1 legacy "" 192.0.2.10 admin 2222
refuses "rename onto an existing name" keys_update 1 web "" 192.0.2.10 admin 2222

succeeds "delete a connection" keys_delete 0
equals "one connection left" "$(keys_count)" "1"
equals "the right one is left" "$(keys_field 0 name)" "legacy"
succeeds "a backup of the previous version is kept" test -f "$KEYS_FILE.bak"
succeeds "the file is still valid JSON" jq -e . "$KEYS_FILE"

echo
if [ "$failures" -eq 0 ]; then echo "All checks passed."; else echo "$failures check(s) failed."; fi
exit "$failures"
