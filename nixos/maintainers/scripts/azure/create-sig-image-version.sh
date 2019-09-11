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

./az.sh group create -n "${group}" -l "westus2"
./az.sh sig create \
  --resource-group "${group}" \
  --gallery-name "${gallery}"

./az.sh sig image-definition create \
  --resource-group "${group}" \
  --gallery-name "${gallery}" \
  --gallery-image "${sig_imagename}" \
  --publisher "${publisher}" \
  --offer "${offer}" \
  --sku "${sku}" \
  --os-type "linux"

./az.sh sig image-version create \
  --resource-group "${group}" \
  --gallery-name "${gallery}" \
  --gallery-image-definition "${sig_imagename}" \
  --gallery-image-version "${sig_imageversion}" \
  --target-regions "WestCentralUS" "WestUS2" "WestUS" \
  --replica-count 2 \
  --managed-image "${imageid}"

./az.sh sig image-version show \
  --resource-group "${group}" \
  --gallery-name "${gallery}" \
  --gallery-image-definition "${sig_imagename}" \
  --gallery-image-version "${sig_imageversion}" \
    | jq -r ".id"
