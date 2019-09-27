#!/usr/bin/env bash
set -x
set -euo pipefail

### USAGE:   ./create-sig-image-version.sh <image_version> <image_id>
### EXAMPLE: ./create-sig-image-version.sh \
#                1.0.0 \
#                /subscriptions/xx-xx-xx/resourceGroups/g1/disks/nixos-disk1.vhd

group="${group:-"nixosimages"}"

sig_imageversion="${1}"; shift
imageid="${1}"; shift

gallery="nixosvhds"
publisher="nixos"
offer="nixos"
sku="nixos"
sig_imagename="nixos"

az group create -n "${group}" -l "uksouth"
az sig create \
  --resource-group "${group}" \
  --gallery-name "${gallery}"

az sig image-definition create \
  --resource-group "${group}" \
  --gallery-name "${gallery}" \
  --gallery-image "${sig_imagename}" \
  --publisher "${publisher}" \
  --offer "${offer}" \
  --sku "${sku}" \
  --os-type "linux"

az sig image-version create \
  --resource-group "${group}" \
  --gallery-name "${gallery}" \
  --gallery-image-definition "${sig_imagename}" \
  --gallery-image-version "${sig_imageversion}" \
  --target-regions "WestCentralUS" "Uksouth" "WestUS" \
  --replica-count 2 \
  --managed-image "${imageid}"

az sig image-version show \
  --resource-group "${group}" \
  --gallery-name "${gallery}" \
  --gallery-image-definition "${sig_imagename}" \
  --gallery-image-version "${sig_imageversion}" \
    | jq -r ".id"
