#!/bin/bash

# Checks of lib/certs.sh with self-signed certificates made here (no network).
# Run with: bash certs/tests/certs.test.sh

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
source "$DIR/../../ssh/lib/colors.sh"
source "$DIR/../lib/certs.sh"

failures=0
pass() { echo "ok   $1"; }
fail() { echo "FAIL $1"; failures=$((failures + 1)); }
equals() { if [ "$2" == "$3" ]; then pass "$1"; else fail "$1 (got '$2', expected '$3')"; fi; }
between() { if [ "$2" -ge "$3" ] && [ "$2" -le "$4" ]; then pass "$1"; else fail "$1 (got $2, expected $3 to $4)"; fi; }

make_cert() { # file days
  openssl req -x509 -newkey rsa:2048 -nodes -keyout "$TMP/key.pem" -out "$1" -days "$2" -subj "/CN=test.local" > /dev/null 2>&1
}
make_cert "$TMP/ok.pem" 40
make_cert "$TMP/warn.pem" 15
make_cert "$TMP/crit.pem" 3

between "a 40-day certificate has about 40 days left" "$(certs_days_left < "$TMP/ok.pem")" 39 40
between "a 3-day certificate has about 3 days left" "$(certs_days_left < "$TMP/crit.pem")" 2 3
equals "a bad certificate is refused" "$(echo "not a cert" | certs_days_left 2> /dev/null; echo "rc=$?")" "rc=1"

equals "40 days is ok" "$(certs_status 40)" "ok"
equals "21 days is a warning" "$(certs_status 21)" "warn"
equals "8 days is a warning" "$(certs_status 8)" "warn"
equals "7 days is critical" "$(certs_status 7)" "crit"
equals "an expired certificate is critical" "$(certs_status -3)" "crit"
equals "the thresholds can be changed" "$(CERTS_WARN=60 certs_status 40)" "warn"

equals "an openssl date is read" "$(date -u -d "@$(certs_epoch 'Jan  1 00:00:00 2030 GMT')" +%F 2> /dev/null || date -u -r "$(certs_epoch 'Jan  1 00:00:00 2030 GMT')" +%F)" "2030-01-01"

# The whole table, with the certificates served from files
certs_fetch_pem() {
  case "$1" in
    ok.local) cat "$TMP/ok.pem" ;;
    warn.local) cat "$TMP/warn.pem" ;;
    crit.local) cat "$TMP/crit.pem" ;;
    *) return 1 ;;
  esac
}
printf '# a comment\nok.local\n\nok.local:8443  # with a port\n' > "$TMP/all-ok.txt"
certs_check_all "$TMP/all-ok.txt" > "$TMP/out.txt"; code=$?
equals "all good: exit code 0" "$code" "0"
equals "a table row per host" "$(wc -l < "$TMP/out.txt" | tr -d ' ')" "3"

printf 'ok.local\nwarn.local\n' > "$TMP/warn.txt"
certs_check_all "$TMP/warn.txt" > /dev/null; equals "a warning: exit code 1" "$?" "1"
printf 'ok.local\nwarn.local\ncrit.local\n' > "$TMP/crit.txt"
certs_check_all "$TMP/crit.txt" > /dev/null; equals "a critical certificate: exit code 2" "$?" "2"
printf 'ok.local\ndown.local\n' > "$TMP/down.txt"
certs_check_all "$TMP/down.txt" > "$TMP/down.out"; code=$?
equals "an unreachable host: exit code 2" "$code" "2"
equals "it is named in the table" "$(sed 's/\x1b\[[0-9;]*m//g' "$TMP/down.out" | grep -c 'down.local.*unreachable')" "1"
certs_check_all "$TMP/missing.txt" > /dev/null 2>&1; equals "a missing list is an error" "$?" "1"

echo
if [ "$failures" -eq 0 ]; then echo "All checks passed."; else echo "$failures check(s) failed."; fi
exit "$failures"
