#!/bin/bash

# Get Databricks scoped AAD token for a user, with interactive login

az logout
az login --allow-no-subscriptions
az account get-access-token \
    --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d \
    --query "accessToken" \
    | jq .
