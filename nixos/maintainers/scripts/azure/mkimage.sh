#!/usr/bin/env bash

# usage(s):
#  export AZURE_SUBSCRIPTION_ID="aff271ee-e9be-4441-b9bb-42f5af4cbaeb"
#  copy "https://nixos.net/nixos.vhd"
#  ./mkimage.sh upload "result/nixos.19.03-git-abcdef.vhd"
#  ./mkimage.sh upload "result/disk.vhd" "nixos.19.03-git-abcdef.vhd"
#  ./mkimage.sh copy "<url from inet>" "nixos.19.03-git-abcdef.vhd"

# God I fucking hate Azure.
# I don't want N resource groups for N locations
# So the literal only other option is to stuff the god damn location
# into the image (and blob, for congruency's sake).
# which makes copying a pain in the ass because we're going to need the user
# to either tell us the source AND destination blob names...
# or we have to sort of intelligently try to trim off the azure location name frm
# the blob, but we can't guarantee teh copied blob fits our filename format. STUPID
# maybe we can stash the original VHD name in an attribute and retrieve it later
# and/or use blob metadata to see if WE uploaded this and thus know how to handle it

set -euo pipefail
set -x
function az() { ./az.sh "${@}" --subscription "${AZURE_SUBSCRIPTION_ID}"; }

export AZURE_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-"aff271ee-e9be-4441-b9bb-42f5af4cbaeb"}" 
export AZURE_LOCATION="${AZURE_LOCATION:-"westus2"}"

AZURE_RESOURCE_GROUP="NIXOS_PRODUCTION"
AZURE_STORAGE_CONTAINER="vhds"
#AZURE_STORAGE_TYPE="Premium_LRS" # can't use public access containers with premium storage because *Azure*!
AZURE_STORAGE_TYPE="Standard_LRS"
AZURE_REPLICA=0
AZURE_STORAGE_ACCOUNT="nixos${AZURE_REPLICA}${AZURE_LOCATION}$(echo "${AZURE_SUBSCRIPTION_ID}" | cut -d- -f1)" # note: expert: stg acct uniqueness is hard

if [[ "${1:-}" == "copy" ]]; then
  mode="copy"
  #target="${2}"
  # make azure image with local nixpkgs somehow
  #imgname="$(basename "${target}")"

elif [[ "${1:-}" == "build" ]]; then
  mode="build"
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
  imgname="${imgname::-4}-${AZURE_LOCATION}.vhd"
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
  az storage account create -n "$AZURE_STORAGE_ACCOUNT" -g "${AZURE_RESOURCE_GROUP}" --location "${AZURE_LOCATION}" --sku "$AZURE_STORAGE_TYPE" --kind "StorageV2" >/dev/stderr
export AZURE_STORAGE_CONNECTION_STRING="$(az storage account show-connection-string \
  -n "$AZURE_STORAGE_ACCOUNT" -g "${AZURE_RESOURCE_GROUP}" --query connectionString --output tsv)"
az storage container show -n "$AZURE_STORAGE_CONTAINER" >/dev/stderr || \
  az storage container create \
  --name "$AZURE_STORAGE_CONTAINER" \
  --public-access "container" &>/tmp/azure-cli/azuresucks2
   #>/dev/stderr

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
