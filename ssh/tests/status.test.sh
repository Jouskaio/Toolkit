#!/bin/bash

# Checks of lib/status.sh with a fake ssh and a fake nc (no network, your keys.json and ~/.ssh stay untouched).
# Run with: bash ssh/tests/status.test.sh

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export HOME="$TMP/home"
export KEYS_FILE="$TMP/keys.json"
export FAKE_SSH_LOG="$TMP/ssh.log"
mkdir -p "$HOME/.ssh"
echo "key" > "$HOME/.ssh/id_test"

source "$DIR/../lib/colors.sh"
source "$DIR/../lib/keys.sh"
source "$DIR/../lib/status.sh"
PATH="$DIR/fakebin:$PATH"

failures=0
pass() { echo "ok   $1"; }
fail() { echo "FAIL $1"; failures=$((failures + 1)); }
equals() { if [ "$2" == "$3" ]; then pass "$1"; else fail "$1 (got '$2', expected '$3')"; fi; }

echo '[]' > "$KEYS_FILE"
keys_add web id_test up.example.com deploy ""
keys_add gone id_test down.example.com deploy ""
keys_add legacy "" up.example.org admin 2222
keys_add locked id_test denied.example.com deploy ""
keys_add custom id_test up.example.net deploy 2200
keys_delete 4

equals "an open server with a key is up" "$(status_one 0)" "name=web state=up load=0.42 disk=37% mem=51% pm2=2/3 docker=4"
equals "a closed port is down" "$(status_one 1)" "name=gone state=down"
equals "a password login is only checked for reachability" "$(status_one 2)" "name=legacy state=up-nokey"
equals "a refused key is denied" "$(status_one 3)" "name=locked state=denied"

report=$(status_report | sed 's/\x1b\[[0-9;]*m//g')
equals "the report has a header and a row per server" "$(echo "$report" | wc -l | tr -d ' ')" "5"
equals "rows keep the order of keys.json" "$(echo "$report" | sed -n '2,5p' | awk '{print $1}' | tr '\n' ' ')" "web gone legacy locked "
equals "the metrics are shown" "$(echo "$report" | sed -n 2p | awk '{print $2, $3, $4, $5, $6, $7}')" "up 0.42 37% 51% 4 2/3"

probe=$(sh -c "$STATUS_PROBE")
if [[ "$probe" =~ ^load=[0-9.]+\ disk=[0-9]+%\ mem= ]]; then pass "the real probe runs on this machine ($probe)"; else fail "the real probe ($probe)"; fi

echo '[]' > "$KEYS_FILE"
equals "no connection is a message, not a table" "$(status_report 2>&1 | head -n 1)" "There is no connection yet."

echo
if [ "$failures" -eq 0 ]; then echo "All checks passed."; else echo "$failures check(s) failed."; fi
exit "$failures"
