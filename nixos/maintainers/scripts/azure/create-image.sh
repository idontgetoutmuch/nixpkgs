#!/usr/bin/env bash
set -x
set -euo pipefail

### <CONFIG>
group="nixosvhds"     # target resource group
diskname="nixosDisk1" # disk/image name
size="50"             # disk size in GB
location="westus2"    # (mostly unimportant due to SIG replication)
### </CONFIG>

## MODE
mode="${1}"; shift

if [[ "${1}" == "build" ]]; then
  # build image
  nix-build ../../../ -A foo
  source="/output"
elif [[ "${1}" == "url" ]]; then
  source="${1}"; shift
elif [[ "${1}" == "vhd" ]]; then
  source="${1}"; shift
elif 

sleep 1

## TEMP FOR TESTING
r="$(printf '%0xd' "$(date '+%s')")"
group="nixosvhds-${r}"
diskname="nixosDisk-${r}"
gallery="nixosvhds${r}"
sig_version="${r}"
source="/home/azureuser/disk.vhd"

function azcopy() {
    command /nix/store/z510y8vbdsmbzmvrc502jy84xlj6vsly-azure-storage-azcopy-10.2.1/bin/azure-storage-azcopy "${@}"
}
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
  --blob-type PageBlob 
  
./az.sh disk revoke-access \
  --resource-group "${group}" \
  --name "${diskname}"

diskid="$(./az.sh disk show -g "${group}" -n "${diskname}" -o json | jq -r .id)"

./az.sh image create \
  --resource-group "${group}" \
  --name "${diskname}" \
  --source "${diskid}" \
  --os-type "linux"

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

sig_imageid="$(\
  ./az.sh sig image-version show \
    --resource-group "${group}" \
    --gallery-name "${gallery}" \
    --gallery-image-definition "${sig_imagename}" \
    --gallery-image-version "${sig_imageversion}" \
    | jq -r ".id"
)"

./az.sh vm create \
  --name "vm-${r}" \
  --resource-group "${group}" \
  --image "${sig_imageid}" \
  --admin-username "${USER}" \
  --location "WestCentralUS" \
  --ssh-key-values "$(ssh-add -L)"
