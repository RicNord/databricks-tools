#!/bin/bash
# Note endpoints are still in preview

set -eo pipefail
MAKE_ADMIN=false

function usage() {
    cat <<EOF
    Usage: $0 [ -a ] 

    -a    Add service principal to admin group
    -h    Display this menu

    Notes:
        Expected env variables:
            - DATABRICKS_ACCOUNT_ID
            - DATABRICKS_TOKEN
            - SPN_ID
            - SPN_DISPLAY_NAME

EOF
    exit 1
}

# Parse args
while getopts ":ah" opt; do
    case "${opt}" in
        a) MAKE_ADMIN=true ;;
        h) usage ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

SPN_INSTANCE_COUNT=$(
    curl -X GET \
        "https://accounts.azuredatabricks.net/api/2.0/accounts/${DATABRICKS_ACCOUNT_ID}/scim/v2/ServicePrincipals?filter=applicationId+eq+$SPN_ID" \
        --silent \
        --header "Authorization: Bearer $DATABRICKS_TOKEN" \
        | jq .totalResults
)

if [[ $SPN_INSTANCE_COUNT = 1 ]]; then
    echo ":::: $SPN_ID already exist in account"
elif [[ $SPN_INSTANCE_COUNT = 0 ]]; then
    curl -X POST \
        "https://accounts.azuredatabricks.net/api/2.0/accounts/${DATABRICKS_ACCOUNT_ID}/scim/v2/ServicePrincipals" \
        --silent \
        --header "Authorization: Bearer $DATABRICKS_TOKEN" \
        --data @<(
            jq -n \
                --arg SPN_ID "$SPN_ID" \
                --arg SPN_DISPLAY_NAME "$SPN_DISPLAY_NAME" \
                '
            {
              "applicationId": $SPN_ID,
              "displayName": $SPN_DISPLAY_NAME
            }'
        ) | jq .
    echo ":::: $SPN_ID added to account!"
else
    echo ":::: Unexpected number of results: $SPN_INSTANCE_COUNT"
    exit 1
fi

if [[ "$MAKE_ADMIN" = true ]]; then

    SPN_DATABRICKS_ID=$(
        curl -X GET \
            "https://accounts.azuredatabricks.net/api/2.0/accounts/${DATABRICKS_ACCOUNT_ID}/scim/v2/ServicePrincipals?filter=applicationId+eq+$SPN_ID" \
            --silent \
            --header "Authorization: Bearer $DATABRICKS_TOKEN" \
            | jq '.Resources
            | .[].id' \
            | tr --delete '"'
    )

    curl -X PATCH \
        "https://accounts.azuredatabricks.net/api/2.0/accounts/${DATABRICKS_ACCOUNT_ID}/scim/v2/ServicePrincipals/$SPN_DATABRICKS_ID" \
        --silent \
        --header 'Content-type: application/scim+json' \
        --header "Authorization: Bearer $DATABRICKS_TOKEN" \
        --data @<(
            jq -n \
                '{
              "schemas": [ "urn:ietf:params:scim:api:messages:2.0:PatchOp" ],
              "Operations": [
                {
                  "op": "add",
                  "path": "roles",
                  "value": [
                    {
                      "value": "account_admin"
                    }
                  ]
                }
              ]
            }'
        ) | jq .
    echo ":::: $SPN_ID made account admin"
fi
