#!/bin/bash
# source this file
AAD_TOKEN=$(curl -X POST -H 'Content-Type: application/x-www-form-urlencoded' \
    "https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token" \
    -d "client_id=$SPN_ID" \
    -d "grant_type=client_credentials" \
    -d "scope=2ff814a6-3304-4ab8-85cb-cd0e6f879c1d%2F.default" \
    -d "client_secret=$SPN_SECRET" \
    | jq .access_token \
    | tr -d '"')
