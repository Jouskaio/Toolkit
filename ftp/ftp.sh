#!/bin/bash

# SFTP users locked in their own folder. Run it on the server, as root: `sudo bash ftp/ftp.sh help`.

ROOT_PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_PROJECT/lib/ftp.sh"

usage() {
  cat << 'TEXT'
Usage: ftp.sh <command>

  create <user> [public key file]   create the user, its locked folder and its authorized key
  list                              the users and the size of their files
  password <user>                   set a new random password (shown once)
  quota <user> <size>               limit the disk space (5G, 500M...)
  delete <user> [--purge]           delete the user (--purge also deletes its folder)

FTP_DRY_RUN=1 prints the commands without running them.
TEXT
}

case "$1" in
  create) ftp_create "$2" "$3" ;;
  list) ftp_list ;;
  password) ftp_password "$2" ;;
  quota) ftp_quota "$2" "$3" ;;
  delete) ftp_delete "$2" "$3" ;;
  help | -h | --help | "") usage ;;
  *)
    usage >&2
    exit 1
    ;;
esac
