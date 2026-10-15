#!/bin/bash

# Snapshots with rsync: each run makes a dated folder; files that did not change are hard-linked to the previous snapshot,
# so ten snapshots cost little more than one. The oldest ones are deleted beyond KEEP.
# A local DEST is supported fully; a remote DEST (user@host:/folder) saves with rsync over SSH and rotates through ssh.
# BACKUP_DRY_RUN=1 prints the rsync command instead of running it.

backup_fail() { echo "$*" >&2; return 1; }

# backup_load <config file>: reads the settings and checks them
backup_load() {
  SOURCES="" DEST="" KEEP=7 EXCLUDE="" RSYNC_SSH="" RSYNC_OPTIONS=""
  [ -f "$1" ] || { backup_fail "The config file $1 does not exist (copy backup.example.conf to backup.conf)."; return 1; }
  # shellcheck source=/dev/null
  source "$1"
  [ -n "$SOURCES" ] || { backup_fail "SOURCES is empty."; return 1; }
  [ -n "$DEST" ] || { backup_fail "DEST is empty."; return 1; }
  [[ "$KEEP" =~ ^[0-9]+$ ]] && [ "$KEEP" -ge 1 ] || { backup_fail "KEEP must be a number, 1 or more."; return 1; }
  local source
  for source in $SOURCES; do
    [[ "$source" == /* ]] || { backup_fail "The source $source must be an absolute path."; return 1; }
  done
}

backup_is_remote() { [[ "$DEST" == *:* ]]; }

# backup_name: the folder name of a snapshot, from the date (overridable for tests: BACKUP_NOW)
backup_name() {
  echo "${BACKUP_NOW:-$(date +%Y-%m-%d_%H%M%S)}"
}

# backup_snapshots: the existing snapshots, oldest first (local DEST)
backup_snapshots() {
  find "$DEST" -mindepth 1 -maxdepth 1 -type d -name '20*' 2> /dev/null | sort | sed 's|.*/||'
}

# backup_run: one snapshot, then the rotation
backup_run() {
  local name previous args=() pattern source extra=()
  name=$(backup_name)
  args=(-a --delete --relative)
  for pattern in $EXCLUDE; do args+=(--exclude "$pattern"); done
  [ -n "$RSYNC_SSH" ] && args+=(-e "$RSYNC_SSH")
  read -ra extra <<< "$RSYNC_OPTIONS"
  args+=("${extra[@]}")

  if ! backup_is_remote; then
    mkdir -p "$DEST" || return 1
    previous=$(backup_snapshots | tail -n 1)
    [ -n "$previous" ] && args+=(--link-dest="$DEST/$previous")
  fi

  # --relative keeps the full path of each source inside the snapshot
  # shellcheck disable=SC2086 # SOURCES is a list of paths without spaces on purpose
  set -- $SOURCES
  if [ -n "$BACKUP_DRY_RUN" ]; then
    echo "+ rsync ${args[*]} $* $DEST/$name/"
    return 0
  fi
  for source in "$@"; do
    [ -e "$source" ] || { backup_fail "The source $source does not exist: nothing was saved."; rm -rf "${DEST:?}/$name" 2> /dev/null; return 1; }
  done
  rsync "${args[@]}" "$@" "$DEST/$name/" || { backup_fail "rsync failed: the snapshot $name is incomplete and was removed."; backup_is_remote || rm -rf "${DEST:?}/$name"; return 1; }
  echo "Snapshot $name saved in $DEST."
  backup_rotate
}

# backup_rotate: delete the oldest snapshots beyond KEEP (local DEST)
backup_rotate() {
  backup_is_remote && { echo "Rotation of a remote DEST: delete the old snapshots on the server (KEEP=$KEEP)."; return 0; }
  local total old
  total=$(backup_snapshots | wc -l | tr -d ' ')
  [ "$total" -gt "$KEEP" ] || return 0
  for old in $(backup_snapshots | head -n "$((total - KEEP))"); do
    rm -rf "${DEST:?}/$old"
    echo "Old snapshot $old deleted."
  done
}

# backup_list: the snapshots with their size
backup_list() {
  local name
  for name in $(backup_snapshots); do
    printf "%-22s %s\n" "$name" "$(du -sh "$DEST/$name" | cut -f1)"
  done
}
