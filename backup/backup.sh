#!/bin/bash

# Snapshots of folders with rsync and rotation. `bash backup/backup.sh [backup.conf]`, `bash backup/backup.sh list [backup.conf]`.

ROOT_PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_PROJECT/lib/backup.sh"

command -v rsync > /dev/null || { echo "rsync is required (brew install rsync / apt install rsync)." >&2; exit 1; }

action="run"
[ "$1" == "list" ] && { action="list"; shift; }
backup_load "${1:-$ROOT_PROJECT/backup.conf}" || exit 1

case "$action" in
  list) backup_list ;;
  *) backup_run ;;
esac
