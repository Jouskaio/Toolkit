#!/bin/bash

# SFTP users that are locked in their own folder: /home/<user>/ftp (root-owned, as sshd's chroot needs) with a writable
# files/ folder inside. Run it on the server, as root.
# Overridable: FTP_GROUP (sftpusers), FTP_HOME_ROOT (/home).
# FTP_DRY_RUN=1 prints every command instead of running it (and does not ask for root): used by the tests.

FTP_GROUP="${FTP_GROUP:-sftpusers}"
FTP_HOME_ROOT="${FTP_HOME_ROOT:-/home}"

ftp_say() { echo -e "$*"; }
ftp_fail() { echo "$*" >&2; return 1; }

# ftp_run <command...>: run it, or print it in dry-run mode
ftp_run() {
  if [ -n "$FTP_DRY_RUN" ]; then
    echo "+ $*"
  else
    "$@"
  fi
}

ftp_need_root() {
  [ -n "$FTP_DRY_RUN" ] || [ "$(id -u)" -eq 0 ] || ftp_fail "Run this as root (sudo)."
}

# ftp_validate_user <name>: a Linux login, no way to reach another folder with it
ftp_validate_user() {
  [[ "$1" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || ftp_fail "Invalid user name '$1': use lowercase letters, digits, '_' or '-' (32 characters at most, no leading digit)."
}

# ftp_user_exists <name>
ftp_user_exists() {
  id "$1" > /dev/null 2>&1
}

# ftp_create <user> [public key file]
ftp_create() {
  local user="$1" key_file="$2" home dir
  ftp_validate_user "$user" || return 1
  ftp_need_root || return 1
  if [ -n "$key_file" ] && [ ! -f "$key_file" ]; then
    ftp_fail "The public key file $key_file does not exist."
    return 1
  fi
  home="$FTP_HOME_ROOT/$user"
  dir="$home/ftp"

  if [ -z "$FTP_DRY_RUN" ] && ! getent group "$FTP_GROUP" > /dev/null; then
    ftp_run groupadd "$FTP_GROUP"
  fi
  if [ -z "$FTP_DRY_RUN" ] && ftp_user_exists "$user"; then
    ftp_say "The user $user already exists: it is kept as it is."
  else
    ftp_run useradd -g "$FTP_GROUP" -d "$home" -s /usr/sbin/nologin "$user"
  fi

  # sshd refuses a chroot that is not owned by root and writable by someone else: the upload folder sits inside it
  ftp_run mkdir -p "$dir/files"
  ftp_run chown root:root "$home" "$dir"
  ftp_run chmod 755 "$home" "$dir"
  ftp_run chown "$user:$FTP_GROUP" "$dir/files"
  ftp_say "Folder $dir ready (upload into $dir/files)."

  ftp_run mkdir -p "$home/.ssh"
  if [ -n "$key_file" ]; then
    if [ -n "$FTP_DRY_RUN" ]; then
      echo "+ install $key_file as $home/.ssh/authorized_keys"
    else
      cat "$key_file" >> "$home/.ssh/authorized_keys"
    fi
    ftp_say "The public key was added to $home/.ssh/authorized_keys."
  else
    ftp_say "No public key given: add one later with: ftp.sh create $user <public key file>"
  fi
  ftp_run chown -R "$user:$FTP_GROUP" "$home/.ssh"
  ftp_run chmod 700 "$home/.ssh"
  [ -z "$FTP_DRY_RUN" ] && [ -f "$home/.ssh/authorized_keys" ] && chmod 600 "$home/.ssh/authorized_keys"
  return 0
}

# ftp_list: the members of the group with the size of their files/ folder
ftp_list() {
  local members user size
  members=$(getent group "$FTP_GROUP" 2> /dev/null | cut -d: -f4 | tr ',' ' ')
  if [ -z "$members" ]; then
    ftp_say "No SFTP user in the group $FTP_GROUP."
    return 0
  fi
  printf "%-24s %s\n" "USER" "FILES"
  for user in $members; do
    size=$(du -sh "$FTP_HOME_ROOT/$user/ftp/files" 2> /dev/null | cut -f1)
    printf "%-24s %s\n" "$user" "${size:--}"
  done
}

# ftp_delete <user> [--purge]: the files are kept unless --purge is given
ftp_delete() {
  local user="$1" purge="$2"
  ftp_validate_user "$user" || return 1
  ftp_need_root || return 1
  if [ -z "$FTP_DRY_RUN" ] && ! ftp_user_exists "$user"; then
    ftp_fail "The user $user does not exist."
    return 1
  fi
  ftp_run userdel "$user"
  if [ "$purge" == "--purge" ]; then
    ftp_run rm -rf -- "${FTP_HOME_ROOT:?}/$user"
    ftp_say "User $user and its folder deleted."
  else
    ftp_say "User $user deleted. Its files stay in $FTP_HOME_ROOT/$user (use --purge to remove them)."
  fi
}

# ftp_generate_password: 20 characters, letters and digits (it is typed or pasted without surprise)
ftp_generate_password() {
  LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 20
  echo
}

# ftp_password <user>: a new random password, shown once
ftp_password() {
  local user="$1" password
  ftp_validate_user "$user" || return 1
  ftp_need_root || return 1
  if [ -z "$FTP_DRY_RUN" ] && ! ftp_user_exists "$user"; then
    ftp_fail "The user $user does not exist."
    return 1
  fi
  password=$(ftp_generate_password)
  if [ -n "$FTP_DRY_RUN" ]; then
    echo "+ chpasswd for $user"
  else
    echo "$user:$password" | chpasswd
  fi
  ftp_say "New password for $user (shown once): $password"
}

# ftp_size_to_kib <size>: 500M, 5G, 2T or a plain number of KiB
ftp_size_to_kib() {
  local n unit
  [[ "$1" =~ ^([0-9]+)([KkMmGgTt]?)$ ]] || { ftp_fail "Invalid size '$1': use a number with K, M, G or T (5G)."; return 1; }
  n="${BASH_REMATCH[1]}"
  unit="${BASH_REMATCH[2]}"
  case "$unit" in
    "" | K | k) echo "$n" ;;
    M | m) echo $((n * 1024)) ;;
    G | g) echo $((n * 1024 * 1024)) ;;
    T | t) echo $((n * 1024 * 1024 * 1024)) ;;
  esac
}

# ftp_quota <user> <size>: a hard limit on the disk space (needs quotas enabled on the file system)
ftp_quota() {
  local user="$1" kib mount
  ftp_validate_user "$user" || return 1
  kib=$(ftp_size_to_kib "$2") || return 1
  ftp_need_root || return 1
  if [ -z "$FTP_DRY_RUN" ] && ! command -v setquota > /dev/null; then
    ftp_fail "setquota is missing: install the quota package and enable quotas on the file system."
    return 1
  fi
  mount=$(df -P "$FTP_HOME_ROOT" 2> /dev/null | awk 'NR==2 {print $6}')
  ftp_run setquota -u "$user" "$kib" "$kib" 0 0 "${mount:-/}"
  ftp_say "Quota of $user: $2."
}
