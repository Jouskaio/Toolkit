#!/bin/bash

# Checks of lib/keygen.sh in a temporary HOME, with a fake ssh-copy-id (no server, your ~/.ssh stays untouched).
# Run with: bash ssh/tests/keygen.test.sh

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export HOME="$TMP/home"
export KEYS_FILE="$TMP/keys.json"
export FAKE_SSH_LOG="$TMP/ssh.log"
export KEYGEN_PASSPHRASE=""
mkdir -p "$HOME"

source "$DIR/../lib/colors.sh"
source "$DIR/../lib/keys.sh"
source "$DIR/../lib/keygen.sh"
PATH="$DIR/fakebin:$PATH"

failures=0
pass() { echo "ok   $1"; }
fail() { echo "FAIL $1"; failures=$((failures + 1)); }
succeeds() { local label="$1"; shift; if "$@" > /dev/null 2>&1; then pass "$label"; else fail "$label"; fi; }
refuses() { local label="$1"; shift; if "$@" > /dev/null 2>&1; then fail "$label"; else pass "$label"; fi; }
equals() { if [ "$2" == "$3" ]; then pass "$1"; else fail "$1 (got '$2', expected '$3')"; fi; }

succeeds "a key is generated" keygen_generate demo
equals "the private key is private" "$(ls -l "$HOME/.ssh/demo" | cut -c1-10)" "-rw-------"
equals "the public key is an ed25519 one" "$(cut -d' ' -f1 "$HOME/.ssh/demo.pub")" "ssh-ed25519"
equals "the directory is private" "$(ls -ld "$HOME/.ssh" | cut -c1-10)" "drwx------"
before=$(cat "$HOME/.ssh/demo")
refuses "an existing key is never overwritten" keygen_generate demo
equals "the existing key is unchanged" "$(cat "$HOME/.ssh/demo")" "$before"
refuses "a name with a space" keygen_generate "my key"
refuses "a name with a path" keygen_generate "../escape"

echo '[]' > "$KEYS_FILE"
keys_add web "" server.example.com deploy 2222
keys_set_key 0 demo
equals "the key is given to the connection" "$(keys_field 0 key)" "demo"
succeeds "the public key is installed" keygen_install 0
equals "ssh-copy-id gets the public key, the port and the target" "$(cat "$FAKE_SSH_LOG")" "-i $HOME/.ssh/demo.pub -p 2222 deploy@server.example.com"
keys_set_key 0 ""
equals "an empty key means a password login" "$(keys_field 0 key)" ""
refuses "nothing to install without a key" keygen_install 0

echo
if [ "$failures" -eq 0 ]; then echo "All checks passed."; else echo "$failures check(s) failed."; fi
exit "$failures"
