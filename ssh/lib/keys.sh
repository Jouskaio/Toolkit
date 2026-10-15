#!/bin/bash

# Data layer of keys.json: an array of connections
#   { "name": "...", "key": "file in ~/.ssh or null", "hostname": "...", "client": "user", "port": "22 or null" }
# Every write goes through a temporary file and keeps the previous version in keys.json.bak.
# The file is read from $KEYS_FILE (keys.json next to main.sh by default).

keys_file() {
  echo "${KEYS_FILE:-$(dirname "${BASH_SOURCE[0]}")/../keys.json}"
}

keys_init() {
  local file
  file=$(keys_file)
  [ -f "$file" ] || echo '[]' > "$file"
}

keys_count() {
  jq 'length' "$(keys_file)"
}

# keys_field <index> <field>: empty when the field is null
keys_field() {
  jq -r --argjson i "$1" --arg f "$2" '.[$i][$f] // empty' "$(keys_file)"
}

# keys_name_taken <name> [index to ignore]
keys_name_taken() {
  jq -e --arg n "$1" --argjson skip "${2:--1}" \
    'to_entries | any(.value.name == $n and .key != $skip)' "$(keys_file)" > /dev/null
}

# keys_validate <name> <key> <hostname> <client> <port> <index to ignore>
keys_validate() {
  if ! [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "Invalid name: use letters, digits, '.', '_' or '-' (no space)." >&2
    return 1
  fi
  if keys_name_taken "$1" "$6"; then
    echo "The name '$1' is already used." >&2
    return 1
  fi
  if [ -z "$3" ] || [ -z "$4" ]; then
    echo "The hostname and the user are required." >&2
    return 1
  fi
  if [ -n "$5" ] && { ! [[ "$5" =~ ^[0-9]+$ ]] || [ "$5" -lt 1 ] || [ "$5" -gt 65535 ]; }; then
    echo "Invalid port: use a number between 1 and 65535, or leave it empty." >&2
    return 1
  fi
}

# _keys_write <jq filter> [jq options...]
_keys_write() {
  local file tmp
  file=$(keys_file)
  tmp="$file.tmp"
  cp "$file" "$file.bak" && jq "${@:2}" "$1" "$file" > "$tmp" && mv "$tmp" "$file"
}

# keys_add <name> <key> <hostname> <client> <port>: key and port may be empty
keys_add() {
  keys_validate "$1" "$2" "$3" "$4" "$5" -1 || return 1
  _keys_write '. + [{
      name: $n,
      key: (if $k == "" then null else $k end),
      hostname: $h,
      client: $c,
      port: (if $p == "" then null else $p end)
    }]' --arg n "$1" --arg k "$2" --arg h "$3" --arg c "$4" --arg p "$5"
}

# keys_update <index> <name> <key> <hostname> <client> <port>
keys_update() {
  keys_validate "$2" "$3" "$4" "$5" "$6" "$1" || return 1
  _keys_write '.[$i] = {
      name: $n,
      key: (if $k == "" then null else $k end),
      hostname: $h,
      client: $c,
      port: (if $p == "" then null else $p end)
    }' --argjson i "$1" --arg n "$2" --arg k "$3" --arg h "$4" --arg c "$5" --arg p "$6"
}

# keys_delete <index>
keys_delete() {
  _keys_write 'del(.[$i])' --argjson i "$1"
}

# keys_set_key <index> <key>: change the key of a connection (empty for a password login)
keys_set_key() {
  _keys_write '.[$i].key = (if $k == "" then null else $k end)' --argjson i "$1" --arg k "$2"
}

# Optional fields of a connection: group (a label), jump (a connection name or user@host), forward (local port forwards,
# separated by commas: 8080:localhost:80), last_used (epoch, set by keys_touch).

# keys_set_option <index> <group|jump|forward> <value>: empty removes the option
keys_set_option() {
  case "$2" in
    group) [[ -z "$3" || "$3" =~ ^[A-Za-z0-9._\ -]{1,30}$ ]] || { echo "Invalid group: up to 30 letters, digits, spaces, '.', '_' or '-'." >&2; return 1; } ;;
    jump) [[ -z "$3" || "$3" =~ ^[A-Za-z0-9._@:-]+$ ]] || { echo "Invalid jump host: a connection name or user@host[:port]." >&2; return 1; } ;;
    forward) [[ -z "$3" || "$3" =~ ^[0-9]{1,5}:[A-Za-z0-9._-]+:[0-9]{1,5}(,[0-9]{1,5}:[A-Za-z0-9._-]+:[0-9]{1,5})*$ ]] || { echo "Invalid forward: use localPort:host:remotePort, separated by commas." >&2; return 1; } ;;
    *) echo "Unknown option $2." >&2; return 1 ;;
  esac
  _keys_write '.[$i][$f] = (if $v == "" then null else $v end)' --argjson i "$1" --arg f "$2" --arg v "$3"
}

# keys_touch <index>: remember that the connection was just used
keys_touch() {
  _keys_write '.[$i].last_used = (now | floor)' --argjson i "$1"
}

# keys_order: the indexes of the connections, most recently used first, then by name
keys_order() {
  jq -r 'to_entries | sort_by([-(.value.last_used // 0), .value.name]) | .[].key' "$(keys_file)"
}

# keys_by_name <name>: the index of the connection with this name (nothing when there is none)
keys_by_name() {
  jq -r --arg n "$1" 'to_entries | map(select(.value.name == $n)) | .[0].key // empty' "$(keys_file)"
}
