#!/bin/bash
# Note endpoints are still in preview

set -eo pipefail
MAKE_ADMIN=false

function usage() {
    cat <<EOF
    Usage: $0 [ -a ] 

    -a    Add service principal to admin group
    -h    Display this menu

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
        "$DATABRICKS_HOST/api/2.0/preview/scim/v2/ServicePrincipals?filter=applicationId+eq+$SPN_ID" \
        --silent \
        --header "Authorization: Bearer $DATABRICKS_TOKEN" \
        | jq .totalResults
)

if [[ $SPN_INSTANCE_COUNT = 1 ]]; then
    echo ":::: $SPN_ID already exist in workspace"
elif [[ $SPN_INSTANCE_COUNT = 0 ]]; then
    curl -X POST \
        "$DATABRICKS_HOST/api/2.0/preview/scim/v2/ServicePrincipals" \
        --silent \
        --header 'Content-type: application/scim+json' \
        --header "Authorization: Bearer $DATABRICKS_TOKEN" \
        --data @<(
            jq -n \
                --arg SPN_ID "$SPN_ID" \
                --arg SPN_DISPLAY_NAME "$SPN_DISPLAY_NAME" \
                '
            {
              "schemas": [ "urn:ietf:params:scim:schemas:core:2.0:ServicePrincipal" ],
              "applicationId": $SPN_ID,
              "displayName": $SPN_DISPLAY_NAME
            }'
        )
    echo ":::: $SPN_ID added to workspace!"
else
    echo ":::: Unexpected number of results: $SPN_INSTANCE_COUNT"
    exit 1
fi

if [[ "$MAKE_ADMIN" = true ]]; then

    SPN_DATABRICKS_ID=$(
        curl -X GET \
            "$DATABRICKS_HOST/api/2.0/preview/scim/v2/ServicePrincipals?filter=applicationId+eq+$SPN_ID" \
            --silent \
            --header "Authorization: Bearer $DATABRICKS_TOKEN" \
            | jq '.Resources
            | .[].id' \
            | tr --delete '"'
    )

    ADMIN_GROUP_ID=$(
        curl -X GET \
            "$DATABRICKS_HOST/api/2.0/preview/scim/v2/Groups" \
            --silent \
            -H "Authorization: Bearer $DATABRICKS_TOKEN" \
            | jq '.Resources
            | map(select( .displayName == "admins" ))
            | .[].id'
    )

    curl -X PATCH \
        "$DATABRICKS_HOST/api/2.0/preview/scim/v2/ServicePrincipals/$SPN_DATABRICKS_ID" \
        --header 'Content-type: application/scim+json' \
        --header "Authorization: Bearer $DATABRICKS_TOKEN" \
        --data @<(
            jq -n \
                --arg ADMIN_GROUP_ID "$ADMIN_GROUP_ID" \
                '{
              "schemas": [ "urn:ietf:params:scim:api:messages:2.0:PatchOp" ],
              "Operations": [
                {
                  "op": "add",
                  "path": "groups",
                  "value": [
                    {
                      "value": $ADMIN_GROUP_ID
                    }
                  ]
                }
              ]
            }'
        )
    echo ":::: $SPN_ID added to admins group"
fi
