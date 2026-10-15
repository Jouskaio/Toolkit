#!/bin/bash

# Checks of the groups, the recent order, the jump host, the port forwards and the OpenSSH config import/export
# (a fake ssh logs the command, a temporary HOME keeps your ~/.ssh and your keys.json untouched).
# Run with: bash ssh/tests/comfort.test.sh

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export HOME="$TMP/home"
export KEYS_FILE="$TMP/keys.json"
export FAKE_SSH_LOG="$TMP/ssh.log"
mkdir -p "$HOME/.ssh"
echo key > "$HOME/.ssh/id_test"

source "$DIR/../lib/colors.sh"
source "$DIR/../lib/keys.sh"
source "$DIR/../lib/connect.sh"
source "$DIR/../lib/sshconfig.sh"
PATH="$DIR/fakebin:$PATH"

failures=0
pass() { echo "ok   $1"; }
fail() { echo "FAIL $1"; failures=$((failures + 1)); }
succeeds() { local label="$1"; shift; if "$@" > /dev/null 2>&1; then pass "$label"; else fail "$label"; fi; }
refuses() { local label="$1"; shift; if "$@" > /dev/null 2>&1; then fail "$label"; else pass "$label"; fi; }
equals() { if [ "$2" == "$3" ]; then pass "$1"; else fail "$1 (got '$2', expected '$3')"; fi; }

echo '[]' > "$KEYS_FILE"
keys_add bastion id_test bastion.example.com ops 2200
keys_add db id_test db.internal deploy ""
keys_add web id_test web.example.com deploy ""

# Options
succeeds "a group is set" keys_set_option 1 group prod
equals "the group is stored" "$(keys_field 1 group)" "prod"
refuses "a group with a bad character" keys_set_option 1 group 'a;b'
succeeds "a jump host is set" keys_set_option 1 jump bastion
succeeds "forwards are set" keys_set_option 1 forward 8080:localhost:80,5432:db:5432
refuses "a forward with a bad shape" keys_set_option 1 forward 80
refuses "a forward that is not a number" keys_set_option 1 forward a:b:c
refuses "an unknown option" keys_set_option 1 colour red
succeeds "an empty value removes an option" keys_set_option 1 group ""
equals "the option is gone" "$(keys_field 1 group)" ""

# Order: the last used first, then by name
equals "without use, the order is alphabetical" "$(keys_order | tr '\n' ' ')" "0 1 2 "
keys_touch 2
equals "the last used connection comes first" "$(keys_order | head -n 1)" "2"
equals "a connection is found by name" "$(keys_by_name db)" "1"
equals "an unknown name is empty" "$(keys_by_name nope)" ""

# connect
: > "$FAKE_SSH_LOG"
connect 1 > /dev/null
equals "the jump host (by connection name) and the forwards reach ssh" "$(cat "$FAKE_SSH_LOG")" "-i $HOME/.ssh/id_test -J ops@bastion.example.com:2200 -L 8080:localhost:80 -L 5432:db:5432 deploy@db.internal"
equals "connecting marks the connection as used" "$(keys_order | head -n 1)" "1"

# Export / import
sshconfig_export "$TMP/exported"
equals "the export has a block per connection" "$(grep -c '^Host ' "$TMP/exported")" "3"
equals "the port and the jump host are exported" "$(sed -n '/^Host db/,/^$/p' "$TMP/exported" | tr '\n' ';')" "Host db;  HostName db.internal;  User deploy;  IdentityFile ~/.ssh/id_test;  ProxyJump ops@bastion.example.com:2200;  LocalForward 8080 localhost:80;  LocalForward 5432 db:5432;;"

cat > "$TMP/config" <<'CONF'
Host *
  ServerAliveInterval 30

Host staging
  HostName staging.example.com
  User deploy
  Port 2222
  IdentityFile ~/.ssh/id_test
  ProxyJump bastion

Host web
  HostName another.example.com

Host nas backup
  HostName nas.local

Host plain
CONF
equals "import adds the new concrete hosts only" "$(sshconfig_import "$TMP/config")" "2"
equals "the host with a port, a key and a jump host is imported" "$(keys_field "$(keys_by_name staging)" hostname) $(keys_field "$(keys_by_name staging)" port) $(keys_field "$(keys_by_name staging)" key) $(keys_field "$(keys_by_name staging)" jump)" "staging.example.com 2222 id_test bastion"
equals "an existing name is kept as it is" "$(keys_field "$(keys_by_name web)" hostname)" "web.example.com"
equals "a Host without HostName uses its name" "$(keys_field "$(keys_by_name plain)" hostname)" "plain"
refuses "a missing file" sshconfig_import "$TMP/missing"

echo
if [ "$failures" -eq 0 ]; then echo "All checks passed."; else echo "$failures check(s) failed."; fi
exit "$failures"
