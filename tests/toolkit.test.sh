#!/bin/bash

# Checks of the `toolkit` entry point, of install.sh and of the bash completion, in a temporary HOME.
# Run with: bash tests/toolkit.test.sh

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
mkdir -p "$HOME"

failures=0
pass() { echo "ok   $1"; }
fail() { echo "FAIL $1"; failures=$((failures + 1)); }
equals() { if [ "$2" == "$3" ]; then pass "$1"; else fail "$1 (got '$2', expected '$3')"; fi; }
contains() { if echo "$2" | grep -qF -- "$3"; then pass "$1"; else fail "$1 (missing '$3')"; fi; }

contains "help lists the commands" "$("$ROOT/toolkit" help)" "toolkit status"
equals "no argument is the help" "$("$ROOT/toolkit")" "$("$ROOT/toolkit" help)"
equals "the version is the VERSION file" "$("$ROOT/toolkit" version)" "toolkit $(cat "$ROOT/VERSION")"
"$ROOT/toolkit" nope > /dev/null 2>&1; equals "an unknown command fails" "$?" "1"
equals "the cheatsheets are listed" "$("$ROOT/toolkit" docs | tr '\n' ' ')" "docker git_flow linux nginx tmux "
contains "a cheatsheet is shown" "$("$ROOT/toolkit" docs tmux)" "Cheatsheet tmux"
"$ROOT/toolkit" docs nope > /dev/null 2>&1; equals "an unknown cheatsheet fails" "$?" "1"
contains "ftp goes to ftp.sh" "$("$ROOT/toolkit" ftp help)" "create <user>"

# Install through a symlink, in a temporary folder
bash "$ROOT/install.sh" "$TMP/bin" > "$TMP/install.out"
equals "install makes a symlink" "$(test -L "$TMP/bin/toolkit" && echo yes)" "yes"
equals "the symlink works from anywhere" "$("$TMP/bin/toolkit" version)" "toolkit $(cat "$ROOT/VERSION")"
equals "the cheatsheets are found through the symlink" "$("$TMP/bin/toolkit" docs | wc -l | tr -d ' ')" "5"
equals "the bash completion is installed" "$(test -f "$HOME/.local/share/bash-completion/completions/toolkit" && echo yes)" "yes"
equals "the zsh completion is installed" "$(test -f "$HOME/.zsh/completions/_toolkit" && echo yes)" "yes"
contains "a PATH hint is given when needed" "$(cat "$TMP/install.out")" "Add $TMP/bin to your PATH"
bash "$ROOT/install.sh" --uninstall "$TMP/bin" > /dev/null
equals "uninstall removes the symlink" "$(test -e "$TMP/bin/toolkit" && echo still || echo gone)" "gone"

# Completion
source "$ROOT/completions/toolkit.bash"
complete_with() { COMP_WORDS=("$@"); COMP_CWORD=$((${#COMP_WORDS[@]} - 1)); COMPREPLY=(); _toolkit; echo "${COMPREPLY[*]}"; }
equals "the commands are completed" "$(complete_with toolkit s)" "ssh status"
equals "the ftp commands are completed" "$(complete_with toolkit ftp d)" "delete"
equals "the backup list action is completed" "$(complete_with toolkit backup l | cut -d' ' -f1)" "list"

echo
if [ "$failures" -eq 0 ]; then echo "All checks passed."; else echo "$failures check(s) failed."; fi
exit "$failures"
