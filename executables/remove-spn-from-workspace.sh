#!/bin/bash
# Removes a Service principal form a workspace

set -eo pipefail

SPN_INSTANCE_COUNT=$(
    curl -X GET \
        "$DATABRICKS_HOST/api/2.0/preview/scim/v2/ServicePrincipals?filter=applicationId+eq+$SPN_ID" \
        --silent \
        --header "Authorization: Bearer $DATABRICKS_TOKEN" \
        | jq .totalResults
)

if [[ $SPN_INSTANCE_COUNT = 0 ]]; then
    echo ":::: $SPN_ID does not exist in workspace"
elif [[ $SPN_INSTANCE_COUNT = 1 ]]; then
    SPN_DATABRICKS_ID=$(
        curl -X GET \
            "$DATABRICKS_HOST/api/2.0/preview/scim/v2/ServicePrincipals?filter=applicationId+eq+$SPN_ID" \
            --silent \
            --header "Authorization: Bearer $DATABRICKS_TOKEN" \
            | jq '.Resources
            | .[].id' \
            | tr --delete '"'
    )

    curl -X DELETE \
        "$DATABRICKS_HOST/api/2.0/preview/scim/v2/ServicePrincipals/$SPN_DATABRICKS_ID" \
        --silent \
        --header "Authorization: Bearer $DATABRICKS_TOKEN"

    echo ":::: $SPN_ID removed from workspace"
else
    echo "Unexpected number of results: $SPN_INSTANCE_COUNT"
    exit 1
fi
