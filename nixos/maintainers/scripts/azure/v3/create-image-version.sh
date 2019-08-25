#!/usr/bin/env bash
set -x
set -euo pipefail

group="nixosvhds"     # target resource group
diskname="nixosDisk1" # disk name
size="50"             # disk size in GB
location="westus2"    # (mostly unimportant due to SIG replication)

gallery="nixosvhds" # JFC, FUCKING NAMING REQUIREMENTS, ARE YOU KIDDING ME?!

publisher="nixos"
offer="nixos"
sku="nixos"

sig_imagename="nixos"
sig_imageversion="1.0.0"

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
  --admin-username "azureuser" \
  --location "WestCentralUS" \
  --ssh-key-values "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC9YAN+P0umXeSP/Cgd5ZvoD5gpmkdcrOjmHdonvBbptbMUbI/Zm0WahBDK0jO5vfJ/C6A1ci4quMGCRh98LRoFKFRoWdwlGFcFYcLkuG/AbE8ObNLHUxAwqrdNfIV6z0+zYi3XwVjxrEqyJ/auZRZ4JDDBha2y6Wpru8v9yg41ogeKDPgHwKOf/CKX77gCVnvkXiG5ltcEZAamEitSS8Mv8Rg/JfsUUwULb6yYGh+H6RECKriUAl9M+V11SOfv8MAdkXlYRrcqqwuDAheKxNGHEoGLBk+Fm+orRChckW1QcP89x6ioxpjN9VbJV0JARF+GgHObvvV+dGHZZL1N3jr8WtpHeJWxHPdBgTupDIA5HeL0OCoxgSyyfJncMl8odCyUqE+lqXVz+oURGeRxnIbgJ07dNnX6rFWRgQKrmdV4lt1i1F5Uux9IooYs/42sKKMUQZuBLTN4UzipPQM/DyDO01F0pdcaPEcIO+tp2U6gVytjHhZqEeqAMaUbq7a6ucAuYzczGZvkApc85nIo9jjW+4cfKZqV8BQfJM1YnflhAAplIq6b4Tzayvw1DLXd2c5rae+GlVCsVgpmOFyT6bftSon/HfxwBE4wKFYF7fo7/j6UbAeXwLafDhX+S5zSNR6so1epYlwcMLshXqyJePJNhtsRhpGLd9M3UqyGDAFoOQ== (none)"
