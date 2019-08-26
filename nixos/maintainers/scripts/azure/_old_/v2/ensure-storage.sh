#!/usr/bin/env bash
set -euo pipefail
set -x

function az() { ./az.sh "${@}" --subscription "${AZURE_SUBSCRIPTION_ID}"; }

export AZURE_STORAGE_TYPE="Standard_LRS"

# exit early on subsequent runs
az storage container show --account-name "${AZURE_STORAGE_ACCOUNT_NAME}" -n "${AZURE_STORAGE_CONTAINER}" >/dev/null && exit 0

# ensure resource group
if ! az group show -n "${AZURE_RESOURCE_GROUP}" >/dev/stderr; then
  az group create -l "${AZURE_LOCATION}" -n "${AZURE_RESOURCE_GROUP}" >/dev/stderr
fi

# ensure storage account
az storage account show -n "$AZURE_STORAGE_ACCOUNT_NAME" -g "${AZURE_RESOURCE_GROUP}" >/dev/stderr || \
  az storage account create -n "$AZURE_STORAGE_ACCOUNT_NAME" -g "${AZURE_RESOURCE_GROUP}" --location "${AZURE_LOCATION}" --sku "$AZURE_STORAGE_TYPE" --kind "StorageV2" >/dev/stderr

# ensure storage container
az storage container show --account-name "${AZURE_STORAGE_ACCOUNT_NAME}" -n "${AZURE_STORAGE_CONTAINER}" >/dev/stderr || \
  az storage container create \
  --account-name "${AZURE_STORAGE_ACCOUNT_NAME}" \
  --name "${AZURE_STORAGE_CONTAINER}" \
  --public-access "container" >/dev/stderr

