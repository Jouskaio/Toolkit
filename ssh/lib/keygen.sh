#!/bin/bash
# shellcheck disable=SC2154 # the colors come from lib/colors.sh

# Create an ed25519 key in ~/.ssh and put its public half on a server.
# Needs lib/keys.sh for keygen_install. KEYGEN_PASSPHRASE (even empty) skips the passphrase question: used by the tests.

# keygen_generate <file name>: ~/.ssh/<name> and ~/.ssh/<name>.pub, mode 600 for the private key
keygen_generate() {
  local name="$1" file="$HOME/.ssh/$1"
  if ! [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "Invalid name: use letters, digits, '.', '_' or '-' (no space, no path)." >&2
    return 1
  fi
  if [ -e "$file" ] || [ -e "$file.pub" ]; then
    echo "The key $file already exists: nothing was overwritten." >&2
    return 1
  fi
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  if [ -n "${KEYGEN_PASSPHRASE+set}" ]; then
    ssh-keygen -q -t ed25519 -C "$name@$(hostname -s 2> /dev/null || hostname)" -N "$KEYGEN_PASSPHRASE" -f "$file" > /dev/null
  else
    ssh-keygen -t ed25519 -C "$name@$(hostname -s 2> /dev/null || hostname)" -f "$file"
  fi
  chmod 600 "$file"
}

# keygen_install <index>: ssh-copy-id of the public key of the connection (asks the server password once)
keygen_install() {
  local key client hostname port args=()
  key=$(keys_field "$1" key)
  client=$(keys_field "$1" client)
  hostname=$(keys_field "$1" hostname)
  port=$(keys_field "$1" port)
  if [ -z "$key" ] || [ ! -f "$HOME/.ssh/$key.pub" ]; then
    echo "The connection has no key with a public half ($HOME/.ssh/$key.pub)." >&2
    return 1
  fi
  args=(-i "$HOME/.ssh/$key.pub")
  [ -n "$port" ] && args+=(-p "$port")
  echo -e "${BYellow}Installing the key on $client@$hostname...${Color_Off}"
  ssh-copy-id "${args[@]}" "$client@$hostname"
}
