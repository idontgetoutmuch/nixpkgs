#!/usr/bin/env bash
set -x
set -euo pipefail

### <CONFIG>
group="${group:-"nixosvhds"}"     # target resource group
size="${size:-50}"             # disk size in GB
location="${location:-"uksouth"}"    # (mostly unimportant due to SIG replication)
### </CONFIG>

## MODE
diskname="${1}"; shift
source="${1}"; shift

az group create \
  --name "${group}" \
  --location "${location}"

az disk create \
  --resource-group "${group}" \
  --name "${diskname}" \
  --size-gb "${size}" \
  --for-upload true

timeout=$(( 60 * 60 )) # disk access token timeout
sasurl="$(\
  az disk grant-access \
    --access-level Write \
    --resource-group "${group}" \
    --name "${diskname}" \
    --duration-in-seconds ${timeout} \
      | jq -r '.accessSas'
)"

azcopy copy "${source}" "${sasurl}" \
  --blob-type PageBlob 
  
az disk revoke-access \
  --resource-group "${group}" \
  --name "${diskname}"

diskid="$(az disk show -g "${group}" -n "${diskname}" -o json | jq -r .id)"

az image create \
  --resource-group "${group}" \
  --name "${diskname}" \
  --source "${diskid}" \
  --os-type "linux" >/dev/null

imageid="$(az image show -g "${group}" -n "${diskname}" -o json | jq -r .id)"

echo "${imageid}"
