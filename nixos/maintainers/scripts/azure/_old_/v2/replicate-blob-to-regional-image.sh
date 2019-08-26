#!/usr/bin/env bash

set -euo pipefail
set -x

function az() { ./az.sh "${@}" --subscription "${AZURE_SUBSCRIPTION_ID}"; }

export SOURCE_BLOB="${1}"
imgname="${SOURCE_BLOB##*/}"
imgname="${imgname::-4}-${AZURE_LOCATION}.vhd"

./ensure-storage.sh

az storage blob show --account-name "${AZURE_STORAGE_ACCOUNT_NAME}" --container "${AZURE_STORAGE_CONTAINER}" --name "$imgname" >/dev/stderr || \
  az storage blob copy start \
    --account-name "${AZURE_STORAGE_ACCOUNT_NAME}" \
    --source-uri "${SOURCE_BLOB}" \
    --destination-container "${AZURE_STORAGE_CONTAINER}" \
    --destination-blob "$imgname" >/dev/stderr
  
while true; do
  status="$(az storage blob show --account-name "${AZURE_STORAGE_ACCOUNT_NAME}" --container "${AZURE_STORAGE_CONTAINER}" --name "$imgname")"
  status="$(echo "${status}" | jq -r '.properties.copy.status')"
  [[ "${status}" == "success" || "${status}" == "null" ]] && break
  sleep 5
done;

imgurl="$(az storage blob url --account-name="${AZURE_STORAGE_ACCOUNT_NAME}" -c "${AZURE_STORAGE_CONTAINER}" -n "$imgname" -o json | tr -d "\"")"

az image show -g "${AZURE_RESOURCE_GROUP}" -n "$imgname" >/dev/stderr || \
  az image create \
    --name "$imgname" \
    --source "${imgurl}" \
    --resource-group "${AZURE_RESOURCE_GROUP}" \
    --location "${AZURE_LOCATION}" \
    --storage-sku "Premium_LRS" \
    --os-disk-caching ReadWrite \
    --os-type "Linux" >/dev/stderr

imgid="$(az image show -g "${AZURE_RESOURCE_GROUP}" -n "$imgname" -o tsv --query 'id')"
echo -n <<EOF
  { "image_id": "${imgid}", "image_blob_url": "${imgurl}" }
EOF

