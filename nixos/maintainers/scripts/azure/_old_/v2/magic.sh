#!/usr/bin/env bash
set -euo pipefail
set -x

export AZURE_RESOURCE_GROUP="NIXOS_PRODUCTION2"
export AZURE_LOCATION="westus2"
export AZURE_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-"aff271ee-e9be-4441-b9bb-42f5af4cbaeb"}"
export AZURE_STORAGE_ACCOUNT_NAME="nixos1$(echo "${AZURE_SUBSCRIPTION_ID}" | cut -d- -f1)"
export AZURE_STORAGE_CONTAINER="vhds"

vhdpath="${1}"

bloburl="$(./upload-blob.sh "${vhdpath}")"

while IFS= read -r location; do
  echo ${location}; continue
  export AZURE_LOCATION="${location}"
  export AZURE_REPLICA=0
  #export AZURE_STORAGE_ACCOUNT_NAME="nixos${AZURE_REPLICA}${AZURE_LOCATION}$(echo "${AZURE_SUBSCRIPTION_ID}" | cut -d- -f1)"
  export AZURE_STORAGE_ACCOUNT_ID="nixos_production"
  export AZURE_STORAGE_ACCOUNT_UNIQUE="${AZURE_SUBSCRIPTION_ID}${AZURE_LOCATION}${AZURE_STORAGE_ACCOUNT_ID}${AZURE_REPLICA}"
  export AZURE_STORAGE_ACCOUNT_NAME="$(echo "${AZURE_STORAGE_ACCOUNT_UNIQUE}" | sha512sum | cut -c1-23)"
  ./replicate-blob-to-regional-image.sh "${bloburl}" &>"/tmp/azure-${AZURE_LOCATION}.txt" &
done <<< $(./az.sh account list-locations -o json | jq -r .[].name)

for job in `jobs -p`
do
echo $job
    wait $job || let "FAIL+=1"
done

if [ "$FAIL" == "0" ];
then
echo "YAY!"
else
echo "FAIL! ($FAIL)"
fi
