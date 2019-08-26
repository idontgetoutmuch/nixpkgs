#!/usr/bin/env bash
set -euo pipefail
set -x
function az() { ./az.sh "${@}" --subscription "${AZURE_SUBSCRIPTION_ID}"; }

image="${1}"
target="$(basename "${image}")"

./ensure-storage.sh

az storage blob show --account-name "${AZURE_STORAGE_ACCOUNT_NAME}" -c "${AZURE_STORAGE_CONTAINER}" -n "${target}" >/dev/stderr || \
 az storage blob upload \
    --account-name "${AZURE_STORAGE_ACCOUNT_NAME}" \
    --file "${image}" \
    --container-name "${AZURE_STORAGE_CONTAINER}" \
    --name "${target}" >/dev/stderr

# TODO: check filesize to make sure we got the whole thing up

imgurl="$(az storage blob url --account-name "${AZURE_STORAGE_ACCOUNT_NAME}" -c "${AZURE_STORAGE_CONTAINER}" -n "${target}" -o json | tr -d "\"")"
echo -n "${imgurl}"

