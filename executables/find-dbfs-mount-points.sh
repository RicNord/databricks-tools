#!/bin/bash

set -euo pipefail

STRICT_MODE=false
MANUAL_IGNORE_LIST=''
DEFAULT_IGNORE_LIST='["/mnt/dbacademy-datasets", "/mnt/dbacademy-users", "/mnt/training"]'

function usage() {
    cat <<EOF
    Usage: $0 [ -s ] [ -l MANUAL_IGNORE_LIST ]

    -s    Strict mode, Does not allow any mounted file systems
    -l    List of paths to ignore '["/mnt/whitelisted-path", /mnt/...]'
    -h    Display this menu

EOF
    exit 1
}

# Parse args
while getopts ":sl:h" opt; do
    case "${opt}" in
        s) STRICT_MODE=true ;;
        l) MANUAL_IGNORE_LIST=${OPTARG} ;;
        h) usage ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

[[ $STRICT_MODE = true ]] && [[ $MANUAL_IGNORE_LIST != '' ]] \
    && echo "ERROR Not allowed to use both args -s and -l at the same time" \
    && exit 1

# set ignorelist
if [[ $MANUAL_IGNORE_LIST != '' ]]; then
    IGNORE_MOUNTPOINTS=$MANUAL_IGNORE_LIST
elif [[ $STRICT_MODE = true ]]; then
    IGNORE_MOUNTPOINTS=''
else
    IGNORE_MOUNTPOINTS=$DEFAULT_IGNORE_LIST
fi

PARSED_RESPONSE=$(
    curl -X GET "${DATABRICKS_HOST}/api/2.0/dbfs/list" \
        --silent \
        --data '{ "path": "/mnt" }' \
        -H "Authorization: Bearer $DATABRICKS_TOKEN" \
        | jq . \
        | jq --arg IGNORE_MOUNTPOINTS "$IGNORE_MOUNTPOINTS" \
            '.files 
        | map(select( .path as $in | $IGNORE_MOUNTPOINTS | index($in) | not)) 
        | map(select( .is_dir = true ))'
)

echo "$PARSED_RESPONSE"

NUM_MOUNTPOINTS=$(
    jq '. | length' <<<"$PARSED_RESPONSE"
)

RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'

if [[ $NUM_MOUNTPOINTS -gt 0 ]]; then
    echo -e "${RED}ERROR Number of mount points found: $NUM_MOUNTPOINTS ${NC}"
    exit 1
else
    echo -e "${GREEN}No mount points found ${NC}"
    exit 0
fi
