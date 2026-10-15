#!/bin/bash

# Checks of lib/ftp.sh in dry-run mode: the commands are printed, nothing is created on this machine.
# Run with: bash ftp/tests/ftp.test.sh

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export FTP_DRY_RUN=1
export FTP_HOME_ROOT="$TMP/home"
source "$DIR/../lib/ftp.sh"

failures=0
pass() { echo "ok   $1"; }
fail() { echo "FAIL $1"; failures=$((failures + 1)); }
succeeds() { local label="$1"; shift; if "$@" > /dev/null 2>&1; then pass "$label"; else fail "$label"; fi; }
refuses() { local label="$1"; shift; if "$@" > /dev/null 2>&1; then fail "$label"; else pass "$label"; fi; }
equals() { if [ "$2" == "$3" ]; then pass "$1"; else fail "$1 (got '$2', expected '$3')"; fi; }
contains() { if echo "$2" | grep -qF -- "$3"; then pass "$1"; else fail "$1 (missing '$3' in: $2)"; fi; }

# Names
succeeds "a plain name" ftp_validate_user client_1
refuses "a name with an uppercase letter" ftp_validate_user Client
refuses "a name with a path" ftp_validate_user ../root
refuses "a name starting with a digit" ftp_validate_user 1client
refuses "an empty name" ftp_validate_user ""

# Create
echo "ssh-ed25519 AAAA test" > "$TMP/key.pub"
out=$(ftp_create client "$TMP/key.pub" 2>&1)
contains "the user is created in the group, without a shell" "$out" "+ useradd -g sftpusers -d $TMP/home/client -s /usr/sbin/nologin client"
contains "the chroot is root-owned" "$out" "+ chown root:root $TMP/home/client $TMP/home/client/ftp"
contains "the upload folder belongs to the user" "$out" "+ chown client:sftpusers $TMP/home/client/ftp/files"
contains "the key is installed" "$out" "authorized_keys"
contains "ssh folder is private" "$out" "+ chmod 700 $TMP/home/client/.ssh"
refuses "a missing key file" ftp_create client "$TMP/missing.pub"
refuses "an invalid name is not created" ftp_create "bad name"

# Delete
out=$(ftp_delete client 2>&1)
contains "the files are kept by default" "$out" "Its files stay"
contains "the user is deleted" "$out" "+ userdel client"
out=$(ftp_delete client --purge 2>&1)
contains "the folder is deleted with --purge" "$out" "+ rm -rf -- $TMP/home/client"
refuses "no name, no deletion" ftp_delete ""

# Password
password=$(ftp_generate_password)
equals "a password has 20 characters" "${#password}" "20"
if [[ "$password" =~ ^[A-Za-z0-9]{20}$ ]]; then pass "a password has letters and digits only"; else fail "password charset ($password)"; fi
if [ "$(ftp_generate_password)" != "$(ftp_generate_password)" ]; then pass "two passwords differ"; else fail "two passwords differ"; fi
contains "the password is shown once" "$(ftp_password client 2>&1)" "New password for client (shown once):"

# Quota
equals "500M in KiB" "$(ftp_size_to_kib 500M)" "512000"
equals "5G in KiB" "$(ftp_size_to_kib 5G)" "5242880"
equals "a plain number is KiB" "$(ftp_size_to_kib 1024)" "1024"
refuses "a size with a bad unit" ftp_size_to_kib 5X
refuses "a negative size" ftp_size_to_kib -5G
contains "the quota command is built" "$(ftp_quota client 1G 2>&1)" "setquota -u client 1048576 1048576 0 0"

# List
FTP_GROUP=nonexistent_group_for_tests
equals "an empty group is a message" "$(ftp_list)" "No SFTP user in the group nonexistent_group_for_tests."

echo
if [ "$failures" -eq 0 ]; then echo "All checks passed."; else echo "$failures check(s) failed."; fi
exit "$failures"
