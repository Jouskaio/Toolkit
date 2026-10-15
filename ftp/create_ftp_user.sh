#!/bin/bash

# Kept for the old habit: `bash create_ftp_user.sh <user>`. It is now `bash ftp.sh create <user> [public key file]`.

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "Usage: $0 <username> [public key file]"
  exit 1
fi

exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ftp.sh" create "$@"
