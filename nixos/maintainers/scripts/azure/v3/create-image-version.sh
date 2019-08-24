#!/usr/bin/env bash
set -x
set -euo pipefail

group="nixosvhds"     # target resource group
diskname="nixosDisk1" # disk name
size="50"             # disk size in GB
location="westus2"    # (mostly unimportant due to SIG replication)

gallery="nixosvhds"

publisher="nixos"
offer="nixos"
sku="nixos"

sig_imagename="nixos"
sig_version="1.0.0"

## TEMP FOR TESTING
r="${RANDOM}"
group="nixosvhds-${r}"
diskname="nixosDisk-${r}"
sig_version="${r}"
source="/home/azureuser/disk.vhd"
## /TEMP

./az.sh group create \
  --name "${group}" \
  --location "${location}"

./az.sh disk create \
  --resource-group "${group}" \
  --name "${diskname}" \
  --size-gb "${size}" \
  --for-upload true

timeout=$(( 60 * 60 )) # disk access token timeout
sasurl="$(\
  ./az.sh disk grant-access \
    --access-level Write \
    --resource-group "${group}" \
    --name "${diskname}" \
    --duration-in-seconds ${timeout} \
      | jq -r '.accessSas'
)"

azcopy copy "${source}" "${sasurl}" \
  --blob-type 
  
./az.sh disk revoke-access \
  --resource-group "${group}" \
  --name "${diskname}"

diskid="$(./az.sh disk show -g "${group}" -n "${diskname}" -o json | jq -r .id)"

./az.sh image create \
  --resource-group "${group}" \
  --name "${diskname}" \
  --source "${diskid}" \
  --os-type "linux" \
  --debug

imageid="$(./az.sh image show -g "${group}" -n "${diskname}" -o json | jq -r .id)"

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

./az.sh vm create --help
