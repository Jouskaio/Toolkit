#!/bin/bash

# ATTENTION: run it with `bash main.sh`, not `sh main.sh` (arrays and [[ ]] need bash).
# Connections are stored in keys.json (see keys.example.json); that file is never committed.

ROOT_PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYS_FILE="${KEYS_FILE:-$ROOT_PROJECT/keys.json}"

source "$ROOT_PROJECT/lib/colors.sh"
source "$ROOT_PROJECT/lib/keys.sh"
source "$ROOT_PROJECT/lib/connect.sh"
source "$ROOT_PROJECT/lib/keygen.sh"

# ------------- DEPENDENCIES -------------
# check_dependency <command> <apt package> [brew package]
check_dependency() {
  command -v "$1" > /dev/null && return 0
  read -rp $'\033[1;33m'"$1 is missing. Install it? Y/n "$'\033[0m: ' ANSWER
  if [[ -z "$ANSWER" || "$ANSWER" == "Y" || "$ANSWER" == "y" ]]; then
    if command -v apt > /dev/null; then
      sudo apt update && sudo apt install -y "$2"
    elif command -v brew > /dev/null; then
      brew install "${3:-$2}"
    else
      echo -e "${Red}>>> Install $1 manually.${Color_Off}"
    fi
  fi
  command -v "$1" > /dev/null
}

check_dependency jq jq || exit 1
check_dependency whiptail whiptail newt || exit 1
keys_init

# ------------- DIALOGS -------------
# whiptail prints its answer on stderr: 3>&1 1>&2 2>&3 swaps it with stdout so we can capture it.
ask() { # title, question, default value
  whiptail --title "$1" --inputbox "$2" 11 72 "$3" 3>&1 1>&2 2>&3
}

msg() {
  whiptail --msgbox "$1" 12 72
}

connection_label() { # index
  echo "$(keys_field "$1" name)  ($(keys_field "$1" client)@$(keys_field "$1" hostname))"
}

# Menu entries are passed as separate arguments, so names may contain any character.
main_menu() {
  local args=() i=0 count
  count=$(keys_count)
  while [ "$i" -lt "$count" ]; do
    args+=("$i" "$(connection_label "$i")")
    i=$((i + 1))
  done
  args+=("add" "+ Add a connection" "edit" "~ Edit a connection" "delete" "- Delete a connection" "keygen" "* Generate a key" "quit" "Quit")
  whiptail --title "SSH connexion" --backtitle "Menu" --nocancel \
    --menu "Select the connection you want to use." 0 0 10 "${args[@]}" 3>&1 1>&2 2>&3
}

pick_connection() { # title
  local args=() i=0 count
  count=$(keys_count)
  if [ "$count" -eq 0 ]; then
    msg "There is no connection yet."
    return 1
  fi
  while [ "$i" -lt "$count" ]; do
    args+=("$i" "$(connection_label "$i")")
    i=$((i + 1))
  done
  whiptail --title "$1" --menu "Select a connection." 0 0 10 "${args[@]}" 3>&1 1>&2 2>&3
}

# ------------- ACTIONS -------------
# connection_form [index]: add a connection, or edit the one at this index
connection_form() {
  local index="$1" title="Add a connection" name="" client="" hostname="" port="" key="" error
  if [ -n "$index" ]; then
    title="Edit a connection"
    name=$(keys_field "$index" name)
    client=$(keys_field "$index" client)
    hostname=$(keys_field "$index" hostname)
    port=$(keys_field "$index" port)
    key=$(keys_field "$index" key)
  fi

  name=$(ask "$title" "Name (letters, digits, '.', '_' or '-'; no space):" "$name") || return 1
  client=$(ask "$title" "User on the server:" "$client") || return 1
  hostname=$(ask "$title" "Hostname or IP:" "$hostname") || return 1
  port=$(ask "$title" "Port (empty for the default one):" "$port") || return 1
  key=$(ask "$title" "Private key: absolute path (copied to ~/.ssh) or a file already in ~/.ssh. Empty for a password login." "$key") || return 1

  if [[ "$key" == */* ]]; then
    if ! key=$(install_key "$key" 2>&1); then
      msg "$key"
      return 1
    fi
  fi

  if [ -n "$index" ]; then
    error=$(keys_update "$index" "$name" "$key" "$hostname" "$client" "$port" 2>&1) || { msg "$error"; return 1; }
  else
    error=$(keys_add "$name" "$key" "$hostname" "$client" "$port" 2>&1) || { msg "$error"; return 1; }
  fi
}

delete_connection() {
  local index
  index=$(pick_connection "Delete a connection") || return 1
  if whiptail --title "Delete a connection" --yesno "Delete '$(keys_field "$index" name)'? The previous list stays in keys.json.bak." 9 72; then
    keys_delete "$index"
  fi
}

# generate_key: a new ed25519 key, then (optionally) given to a connection and installed on its server
generate_key() {
  local name index errors
  name=$(ask "Generate a key" "File name of the new key in ~/.ssh (letters, digits, '.', '_' or '-'):" "id_ed25519_$(date +%Y)") || return 1
  clear
  errors=$(mktemp)
  # ssh-keygen asks its passphrase on the terminal; only its errors are kept for the message box
  if ! keygen_generate "$name" 2> "$errors"; then
    msg "$(cat "$errors")"
    rm -f "$errors"
    return 1
  fi
  rm -f "$errors"
  index=$(pick_connection "Use the key $name for a connection (Esc to skip)") || return 0
  keys_set_key "$index" "$name"
  if whiptail --title "Install the key" --yesno "Install $name.pub on '$(keys_field "$index" name)' now? The server asks its password once." 9 72; then
    clear
    keygen_install "$index" || msg "The installation failed: the key is kept, you can install it by hand with ssh-copy-id."
  fi
}

# ------------- MAIN LOOP -------------
clear
while true; do
  CHOICE=$(main_menu)
  case "$CHOICE" in
    add) connection_form "" ;;
    edit) INDEX=$(pick_connection "Edit a connection") && connection_form "$INDEX" ;;
    delete) delete_connection ;;
    keygen) generate_key ;;
    quit) break ;;
    *)
      connect "$CHOICE"
      break
      ;;
  esac
done
