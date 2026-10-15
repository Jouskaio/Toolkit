#!/bin/bash

# Expiry dates of the TLS certificates of your domains: `bash certs/certs.sh [domains.txt]`.
# The exit code is 0 (all good), 1 (a certificate expires soon) or 2 (critical or unreachable): usable in a cron job.

ROOT_PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_PROJECT/../ssh/lib/colors.sh"
source "$ROOT_PROJECT/lib/certs.sh"

command -v openssl > /dev/null || { echo "openssl is required." >&2; exit 1; }
certs_check_all "${1:-$ROOT_PROJECT/domains.txt}"
