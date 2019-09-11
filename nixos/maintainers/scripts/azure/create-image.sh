#!/usr/bin/env bash
set -x
set -euo pipefail

### <CONFIG>
group="nixosvhds"     # target resource group
size="50"             # disk size in GB
location="westus2"    # (mostly unimportant due to SIG replication)
### </CONFIG>

## MODE
diskname="${1}"; shift
source="${1}"; shift

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
