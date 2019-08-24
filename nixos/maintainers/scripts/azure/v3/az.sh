#!/usr/bin/env bash

sudo docker run \
  -v /nix:/nix \
  -v /tmp/azure-cli:/tmp/azure-cli \
  -e "AZURE_CONFIG_DIR=/tmp/azure-cli" \
  -e "AZURE_USER=${AZURE_USER:-"azureuser"}" \
  -e "AZURE_STORAGE_CONNECTION_STRING=${AZURE_STORAGE_CONNECTION_STRING}" \
  microsoft/azure-cli:latest az "${@}"

