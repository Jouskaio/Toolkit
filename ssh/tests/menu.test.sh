#!/bin/bash

# Drives main.sh with a fake whiptail: add, refuse a duplicate, edit, install a key, delete.
# Everything happens in temporary files and a temporary HOME (your keys.json and ~/.ssh stay untouched).
# Run with: bash ssh/tests/menu.test.sh

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export HOME="$TMP/home"
export KEYS_FILE="$TMP/keys.json"
export FAKE_ANSWERS="$TMP/answers"
export TERM=dumb
export KEYGEN_PASSPHRASE=""
export FAKE_SSH_LOG="$TMP/ssh.log"
mkdir -p "$HOME"
echo "private key" > "$TMP/id_test"

# One line per dialog, in the order main.sh asks them.
cat > "$FAKE_ANSWERS" << EOF
add
web
deploy
server.example.com


add
web
me
other.example.com


edit
0
web
deploy
edited.example.com
2222

add
second
user
b.example.com


add
withkey
user
c.example.com

$TMP/id_test
delete
0
yes
keygen
gen_key
0
yes
quit
EOF

PATH="$DIR/fakebin:$PATH" bash "$DIR/../main.sh" > /dev/null 2>&1

failures=0
pass() { echo "ok   $1"; }
fail() { echo "FAIL $1"; failures=$((failures + 1)); }
equals() { if [ "$2" == "$3" ]; then pass "$1"; else fail "$1 (got '$2', expected '$3')"; fi; }

equals "two connections are left" "$(jq length "$KEYS_FILE")" "2"
equals "the first one was deleted" "$(jq -r '.[0].name' "$KEYS_FILE")" "second"
equals "the key given as a path is stored by name" "$(jq -r '.[1].key' "$KEYS_FILE")" "id_test"
equals "the key was copied to ~/.ssh" "$(cat "$HOME/.ssh/id_test" 2> /dev/null)" "private key"
equals "the key is private" "$(ls -l "$HOME/.ssh/id_test" | cut -c1-10)" "-rw-------"
equals "the generated key is given to the connection" "$(jq -r '.[0].key' "$KEYS_FILE")" "gen_key"
equals "the generated key exists" "$(cut -d' ' -f1 "$HOME/.ssh/gen_key.pub")" "ssh-ed25519"
equals "the generated key was installed" "$(cat "$FAKE_SSH_LOG")" "-i $HOME/.ssh/gen_key.pub user@b.example.com"
equals "the duplicate name was refused with a message" "$(grep -c "already used" "$FAKE_ANSWERS.messages")" "1"
equals "all answers were consumed" "$(grep -c . "$FAKE_ANSWERS")" "0"

echo
if [ "$failures" -eq 0 ]; then echo "All checks passed."; else echo "$failures check(s) failed."; fi
exit "$failures"
