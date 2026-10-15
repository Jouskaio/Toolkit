#!/bin/bash

# SSH side: put a private key in ~/.ssh and open a connection described in keys.json.
# Needs lib/keys.sh and lib/colors.sh.

# install_key <path>: copy the key into ~/.ssh with the right permissions, print its file name
install_key() {
  local source="$1" destination
  destination="$HOME/.ssh/$(basename "$1")"
  if [ ! -f "$source" ]; then
    echo "The file $source does not exist." >&2
    return 1
  fi
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  [ "$source" -ef "$destination" ] || cp "$source" "$destination"
  chmod 600 "$destination" && basename "$destination"
}

# connect <index>
connect() {
  local key client hostname port
  key=$(keys_field "$1" key)
  client=$(keys_field "$1" client)
  hostname=$(keys_field "$1" hostname)
  port=$(keys_field "$1" port)

  local args=()
  if [ -n "$key" ]; then
    if [ ! -f "$HOME/.ssh/$key" ]; then
      echo -e "${Red}>>> The key $HOME/.ssh/$key does not exist. Edit the connection to give its path.${Color_Off}"
      return 1
    fi
    args+=(-i "$HOME/.ssh/$key")
  fi
  [ -n "$port" ] && args+=(-p "$port")

  echo -e "${BYellow}Connecting to $client@$hostname...${Color_Off}\n"
  ssh "${args[@]}" "$client@$hostname"
}
