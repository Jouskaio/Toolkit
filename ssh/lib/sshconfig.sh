#!/bin/bash

# Exchange connections with an OpenSSH config file (~/.ssh/config). Needs lib/keys.sh.
# The real ~/.ssh/config is only ever read; an export goes to a file of your choice.

# sshconfig_export <file>: one Host block per connection
sshconfig_export() {
  local file="$1" count i name
  count=$(keys_count)
  : > "$file" || return 1
  i=0
  while [ "$i" -lt "$count" ]; do
    name=$(keys_field "$i" name)
    {
      echo "Host $name"
      echo "  HostName $(keys_field "$i" hostname)"
      echo "  User $(keys_field "$i" client)"
      [ -n "$(keys_field "$i" port)" ] && echo "  Port $(keys_field "$i" port)"
      [ -n "$(keys_field "$i" key)" ] && echo "  IdentityFile ~/.ssh/$(keys_field "$i" key)"
      [ -n "$(keys_field "$i" jump)" ] && echo "  ProxyJump $(connect_target "$(keys_field "$i" jump)")"
      [ -n "$(keys_field "$i" forward)" ] && keys_field "$i" forward | tr ',' '\n' | sed 's/^\([0-9]*\):\(.*\)$/  LocalForward \1 \2/'
      echo
    } >> "$file"
    i=$((i + 1))
  done
}

# _sshconfig_blocks <file>: one line per concrete Host: name|hostname|user|port|identityfile|proxyjump
_sshconfig_blocks() {
  awk '
    function flush() { if (host != "") print host "|" hn "|" user "|" port "|" idf "|" pj; host = ""; hn = ""; user = ""; port = ""; idf = ""; pj = "" }
    tolower($1) == "host" { flush(); if ($2 !~ /[*?!]/ && NF == 2) host = $2; next }
    tolower($1) == "hostname" { hn = $2 }
    tolower($1) == "user" { user = $2 }
    tolower($1) == "port" { port = $2 }
    tolower($1) == "identityfile" { idf = $2 }
    tolower($1) == "proxyjump" { pj = $2 }
    END { flush() }
  ' "$1"
}

# sshconfig_import <file>: add the hosts that are not in keys.json yet; prints the number of connections added
sshconfig_import() {
  local file="$1" line name hostname user port idf pj key added=0
  [ -f "$file" ] || { echo "The file $file does not exist." >&2; return 1; }
  while IFS='|' read -r name hostname user port idf pj; do
    [ -n "$name" ] || continue
    [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || continue
    [ -n "$(keys_by_name "$name")" ] && continue
    [ -n "$hostname" ] || hostname="$name"
    [ -n "$user" ] || user="$USER"
    key=""
    case "$idf" in
      \~/.ssh/*) key="${idf#\~/.ssh/}" ;;
      "$HOME/.ssh/"*) key="${idf#"$HOME/.ssh/"}" ;;
    esac
    if keys_add "$name" "$key" "$hostname" "$user" "$port" 2> /dev/null; then
      [ -n "$pj" ] && keys_set_option "$(keys_by_name "$name")" jump "$pj" 2> /dev/null
      added=$((added + 1))
    fi
  done < <(_sshconfig_blocks "$file")
  echo "$added"
}
