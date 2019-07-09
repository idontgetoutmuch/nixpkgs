#!/usr/bin/env bash

# usage(s):
#  export AZURE_SUBSCRIPTION_ID="aff271ee-e9be-4441-b9bb-42f5af4cbaeb"
#  copy "https://nixos.net/nixos.vhd"
#  ./mkimage.sh upload "result/nixos.19.03-git-abcdef.vhd"
#  ./mkimage.sh upload "result/disk.vhd" "nixos.19.03-git-abcdef.vhd"
#  ./mkimage.sh copy "<url from inet>" "nixos.19.03-git-abcdef.vhd"

set -euo pipefail
set -x
function az() { ./az.sh "${@}" --subscription "${AZURE_SUBSCRIPTION_ID}"; }

export AZURE_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-"aff271ee-e9be-4441-b9bb-42f5af4cbaeb"}" 
export AZURE_LOCATION="${AZURE_LOCATION:-"westus2"}"

AZURE_RESOURCE_GROUP="NIXOS_PRODUCTION"
AZURE_STORAGE_CONTAINER="vhds"
AZURE_STORAGE_TYPE="Premium_LRS"
AZURE_REPLICA=1
AZURE_STORAGE_ACCOUNT="nixos${AZURE_REPLICA}${AZURE_LOCATION}$(echo "${AZURE_SUBSCRIPTION_ID}" | cut -d- -f1)" # note: expert: stg acct uniqueness is hard

if [[ "${1:-}" == "copy" ]]; then
  mode="copy"
  target="${2}"
  imgname="$(basename "${target}")"

elif [[ "${1:-}" == "upload" ]]; then
  mode="upload"
  target="$(readlink -f "${2}")"
  imgname="$(basename "${target}")"
  # if another arg is passed, use it to override the target blob/img name
  if [[ "${3:-}" != "" ]]; then
    imgname="${3}"
  fi
  imgname="${imgname}"
else
  printf "must specify 'copy <uri>', or 'upload <file>'" >/dev/stderr
  exit -1
fi

if ! az group show -n "${AZURE_RESOURCE_GROUP}" >/dev/stderr; then
  az group create -l "${AZURE_LOCATION}" -n "${AZURE_RESOURCE_GROUP}" >/dev/stderr
fi

if az image show -n "$imgname" -g "${AZURE_RESOURCE_GROUP}" &>/dev/stderr; then
  imgid="$(az image show -g "${AZURE_RESOURCE_GROUP}" -n "$imgname" -o tsv --query 'id')"
  echo -n "${imgid}"
  exit 0
fi

az storage account show -n "$AZURE_STORAGE_ACCOUNT" -g "${AZURE_RESOURCE_GROUP}" >/dev/stderr || \
  az storage account create -n "$AZURE_STORAGE_ACCOUNT" -g "${AZURE_RESOURCE_GROUP}" --sku "$AZURE_STORAGE_TYPE" --kind "StorageV2" >/dev/stderr
export AZURE_STORAGE_CONNECTION_STRING="$(az storage account show-connection-string \
  -n "$AZURE_STORAGE_ACCOUNT" -g "${AZURE_RESOURCE_GROUP}" --query connectionString --output tsv)"
az storage container show -n "$AZURE_STORAGE_CONTAINER" >/dev/stderr || \
  az storage container create \
  --name "$AZURE_STORAGE_CONTAINER" \
   >/dev/stderr
  #--public-access "container" \

az storage blob show --container "$AZURE_STORAGE_CONTAINER" --name "$imgname" >/dev/stderr || \
  (
    if [[ "${mode}" == "upload" ]]; then
      az storage blob upload \
        --file "${target}" \
        --container-name "$AZURE_STORAGE_CONTAINER" \
        --name "$imgname" >/dev/stderr
    elif [[ "${mode}" == "copy" ]]; then
      az storage blob copy start \
        --source-uri "${target}" \
        --destination-container "$AZURE_STORAGE_CONTAINER" \
        --destination-blob "$imgname" >/dev/stderr
    fi
  )
while true; do
  status="$(az storage blob show --container "$AZURE_STORAGE_CONTAINER" --name "$imgname")"
  status="$(echo "${status}" | jq -r '.properties.copy.status')"
  [[ "${status}" == "success" || "${status}" == "null" ]] && break
  sleep 5
done;

imgurl="$(az storage blob url -c "$AZURE_STORAGE_CONTAINER" -n "$imgname" -o json | tr -d "\"")"

az image show -g "${AZURE_RESOURCE_GROUP}" -n "$imgname" >/dev/stderr || \
  az image create \
  --debug \
    --name "$imgname" \
    --source "${imgurl}" \
    --resource-group "${AZURE_RESOURCE_GROUP}" \
    --location "${AZURE_LOCATION}" \
    --storage-sku "Premium_LRS" \
    --os-disk-caching ReadWrite \
    --os-type "Linux" >/dev/stderr

imgid="$(az image show -g "${AZURE_RESOURCE_GROUP}" -n "$imgname" -o tsv --query 'id')"
echo -n "${imgid}"
exit 0
