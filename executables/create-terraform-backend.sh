#!/bin/bash

# Expected Env vars
# RESOURCE_GROUP
# STORAGE_ACCOUNT_NAME
# AZURE_REGION
# STORAGE_ACCOUNT_SKU

NUM_SA=$(az storage account list -g "$RESOURCE_GROUP" \
    | jq \
        --arg STORAGE_ACCOUNT_NAME "$STORAGE_ACCOUNT_NAME" \
        ' map(select( .name == $STORAGE_ACCOUNT_NAME )) | length')
if [ "$NUM_SA" == 0 ]; then
    NAME_AVAILIBLE=$(az storage account check-name --name "$STORAGE_ACCOUNT_NAME" \
        | jq .nameAvailible)
    if [ "$NAME_AVAILIBLE" == "false" ]; then
        echo "Storage account name $STORAGE_ACCOUNT_NAME already taken"
        exit 1
    fi
    az storage account create \
        -n "$STORAGE_ACCOUNT_NAME" \
        -g "$RESOURCE_GROUP" \
        -l "$AZURE_REGION" \
        --sku "$STORAGE_ACCOUNT_SKU"
fi

sleep 5

CONTAINER_EXIST=$(az storage container exists \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --auth-mode "login" \
    --name "tfstate" \
    | jq .exists)
if [ "$CONTAINER_EXIST" == "false" ]; then
    az storage container create \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --auth-mode "login" \
        --name "tfstate"
fi
