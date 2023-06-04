#!/bin/bash

# Args Cluster_id, owner_username

curl -X POST \
    "$DATABRICKS_HOST"/api/2.0/clusters/change-owner \
    --header "Authorization: Bearer $DATABRICKS_TOKEN" \
    --data @<(
        jq -n \
            --arg CLUSTER_ID "$1" \
            --arg OWNER_USERNAME "$2" \
            '{ "cluster_id": "$CLUSTER_ID", "owner_username": "$OWNER_USERNAME" }'
    )
