#!/bin/bash
# shellcheck disable=SC2154 # the colors come from lib/colors.sh

# Health of the servers of keys.json: is the SSH port open, then (with a key) load, disk, memory, pm2 and Docker.
# Needs lib/keys.sh. A password login can only be checked for reachability: asking for it would block the report.
# Overridable for tests: STATUS_TIMEOUT (seconds, default 5).

# status_port_open <hostname> <port>
status_port_open() {
  if command -v nc > /dev/null; then
    nc -z -w "${STATUS_TIMEOUT:-5}" "$1" "$2" > /dev/null 2>&1
  else
    timeout "${STATUS_TIMEOUT:-5}" bash -c "exec 3<>/dev/tcp/$1/$2" > /dev/null 2>&1
  fi
}

# The remote probe prints ONE line of key=value words (no space inside a value), whatever is (not) installed.
# shellcheck disable=SC2016 # it is a script for the remote shell: nothing must expand here
STATUS_PROBE='
l=$(cut -d" " -f1 /proc/loadavg 2>/dev/null)
[ -z "$l" ] && l=$(uptime | sed "s/.*load averages*: *//; s/[, ].*//")
d=$(df -P / | awk "NR==2 {print \$5}")
m=$(free 2>/dev/null | awk "/^Mem:/ {printf \"%d%%\", \$3*100/\$2}")
out="load=$l disk=$d mem=${m:--}"
if command -v pm2 > /dev/null; then
  p=$(pm2 jlist 2>/dev/null)
  out="$out pm2=$(echo "$p" | grep -o "\"status\":\"online\"" | wc -l | tr -d " ")/$(echo "$p" | grep -o "\"status\":\"[a-z]*\"" | wc -l | tr -d " ")"
fi
if command -v docker > /dev/null; then out="$out docker=$(docker ps -q 2>/dev/null | wc -l | tr -d " ")"; fi
echo "$out"
'

# status_one <index>: one line of key=value words (state=up|up-nokey|down|denied)
status_one() {
  local i="$1" name hostname client port key args=() output
  name=$(keys_field "$i" name)
  hostname=$(keys_field "$i" hostname)
  client=$(keys_field "$i" client)
  port=$(keys_field "$i" port)
  key=$(keys_field "$i" key)

  if ! status_port_open "$hostname" "${port:-22}"; then
    echo "name=$name state=down"
    return 0
  fi
  if [ -z "$key" ] || [ ! -f "$HOME/.ssh/$key" ]; then
    echo "name=$name state=up-nokey"
    return 0
  fi

  args=(-i "$HOME/.ssh/$key" -o BatchMode=yes -o ConnectTimeout="${STATUS_TIMEOUT:-5}" -o StrictHostKeyChecking=accept-new)
  [ -n "$port" ] && args+=(-p "$port")
  # shellcheck disable=SC2029 # the probe is expanded here on purpose: it is the remote command
  if ! output=$(ssh "${args[@]}" "$client@$hostname" "$STATUS_PROBE" 2> /dev/null); then
    echo "name=$name state=denied"
    return 0
  fi
  echo "name=$name state=up $output"
}

# status_field <line> <field>: value of a key=value word
status_field() {
  echo "$1" | tr ' ' '\n' | sed -n "s/^$2=//p" | head -n 1
}

# status_report: a table for every connection; all servers are checked at the same time
status_report() {
  local count i tmp line
  count=$(keys_count)
  if [ "$count" -eq 0 ]; then
    echo "There is no connection yet." >&2
    return 1
  fi
  tmp=$(mktemp -d)
  i=0
  while [ "$i" -lt "$count" ]; do
    status_one "$i" > "$tmp/$i" &
    i=$((i + 1))
  done
  wait

  printf "${BYellow}%-22s %-10s %-7s %-6s %-6s %-8s %s${Color_Off}\n" "SERVER" "STATE" "LOAD" "DISK" "MEM" "DOCKER" "PM2 (up/all)"
  i=0
  while [ "$i" -lt "$count" ]; do
    line=$(cat "$tmp/$i")
    status_print_row "$line"
    i=$((i + 1))
  done
  rm -rf "$tmp"
}

status_print_row() {
  local line="$1" name state color
  name=$(status_field "$line" name)
  state=$(status_field "$line" state)
  case "$state" in
    up) color="$Green" ;;
    up-nokey) color="$Yellow" ;;
    *) color="$Red" ;;
  esac
  printf "%-22s ${color}%-10s${Color_Off} %-7s %-6s %-6s %-8s %s\n" "$name" "$state" \
    "$(status_field "$line" load)" "$(status_field "$line" disk)" "$(status_field "$line" mem)" \
    "$(status_field "$line" docker)" "$(status_field "$line" pm2)"
}
