#!/bin/bash

DATABRICKS_GROUP=$1

curl -X PATCH \
    "https://accounts.azuredatabricks.net/api/2.0/accounts/$DATABRICKS_ACCOUNT/scim/v2/Groups/$DATABRICKS_GROUP" \
    --header 'Content-type: application/scim+json' \
    --header "Authorization: Bearer $DATABRICKS_TOKEN" \
    --data @<(
        jq -n \
            '
            {
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
    ) \
    | jq .
