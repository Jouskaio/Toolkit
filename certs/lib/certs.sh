#!/bin/bash
# shellcheck disable=SC2154 # the colors come from ssh/lib/colors.sh

# Expiry dates of the TLS certificates of your domains.
# CERTS_WARN (days, default 21) and CERTS_CRIT (default 7) set the thresholds. Exit code: 0 all good, 1 a warning, 2 critical or unreachable.

certs_fail() { echo "$*" >&2; return 1; }

# certs_fetch_pem <host> <port>: the certificate the server presents (overridden in the tests)
certs_fetch_pem() {
  local host="$1" port="$2"
  if command -v nc > /dev/null && ! nc -z -w 5 "$host" "$port" > /dev/null 2>&1; then
    return 1
  fi
  openssl s_client -servername "$host" -connect "$host:$port" < /dev/null 2> /dev/null | openssl x509 2> /dev/null
}

# certs_epoch <openssl date, e.g. "Jan  1 00:00:00 2027 GMT">: seconds since 1970, on macOS and on Linux
certs_epoch() {
  date -u -d "$1" +%s 2> /dev/null && return 0
  date -u -j -f "%b %e %H:%M:%S %Y %Z" "$1" +%s 2> /dev/null
}

# certs_not_after <pem on stdin>: the end date as openssl prints it
certs_not_after() {
  openssl x509 -noout -enddate 2> /dev/null | sed 's/^notAfter=//'
}

# certs_days_left <pem on stdin>: whole days before the expiry (negative once expired)
certs_days_left() {
  local end epoch
  end=$(certs_not_after)
  [ -n "$end" ] || return 1
  epoch=$(certs_epoch "$end") || return 1
  echo $(((epoch - $(date -u +%s)) / 86400))
}

# certs_status <days>: ok, warn or crit
certs_status() {
  if [ "$1" -le "${CERTS_CRIT:-7}" ]; then echo crit
  elif [ "$1" -le "${CERTS_WARN:-21}" ]; then echo warn
  else echo ok
  fi
}

# certs_check_all <file>: a table, and the exit code of the worst result
certs_check_all() {
  local file="$1" line host port pem days status code=0 color
  [ -f "$file" ] || { certs_fail "The list $file does not exist (copy domains.example.txt to domains.txt)."; return 1; }
  printf "${BYellow}%-32s %-12s %-6s %s${Color_Off}\n" "HOST" "EXPIRES" "DAYS" "STATUS"
  while read -r line; do
    line="${line%%#*}"
    line="${line//[[:space:]]/}"
    [ -n "$line" ] || continue
    host="${line%%:*}"
    port=443
    [[ "$line" == *:* ]] && port="${line##*:}"
    if ! pem=$(certs_fetch_pem "$host" "$port") || [ -z "$pem" ]; then
      printf "%-32s %-12s %-6s ${Red}%s${Color_Off}\n" "$host" "-" "-" "unreachable"
      code=2
      continue
    fi
    days=$(echo "$pem" | certs_days_left) || { printf "%-32s %-12s %-6s ${Red}%s${Color_Off}\n" "$host" "-" "-" "unreadable"; code=2; continue; }
    status=$(certs_status "$days")
    case "$status" in
      ok) color="$Green" ;;
      warn) color="$Yellow"; [ "$code" -lt 1 ] && code=1 ;;
      *) color="$Red"; code=2 ;;
    esac
    printf "%-32s %-12s %-6s ${color}%s${Color_Off}\n" "$host" "$(date -u -d "@$(certs_epoch "$(echo "$pem" | certs_not_after)")" +%F 2> /dev/null || date -u -r "$(certs_epoch "$(echo "$pem" | certs_not_after)")" +%F)" "$days" "$status"
  done < "$file"
  return "$code"
}
