#!/bin/bash

# Health of every server of keys.json in one table. Run it with `bash ssh/status.sh`.

ROOT_PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYS_FILE="${KEYS_FILE:-$ROOT_PROJECT/keys.json}"

source "$ROOT_PROJECT/lib/colors.sh"
source "$ROOT_PROJECT/lib/keys.sh"
source "$ROOT_PROJECT/lib/status.sh"

command -v jq > /dev/null || { echo "jq is required (brew install jq / apt install jq)." >&2; exit 1; }
keys_init
status_report
