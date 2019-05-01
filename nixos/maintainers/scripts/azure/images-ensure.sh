#!/usr/bin/env bash
set -euo pipefail
set -x

# look ma, no NIX_PATH!
unset NIXOS_CONFIG
unset NIX_PATH

OUTDIR="./result"
images="../../../modules/virtualisation/azure-images.nix"

function build() {
  rev="${1}"
  nix-build "${images}" -A "${rev}.image" --out-link "result/${rev}" &> "result/${rev}_buildlog";
  
  # note, this saves the nice label name separately (used for old images that
  # just name their output disk "disk.vhd")
  nix eval -f "${images}" "${rev}.imageName" --raw > "result/${rev}_name"
}

rm -rf "${OUTDIR}"
mkdir -p "${OUTDIR}"

# TODO: replace this with something that lists out the
# images that don't have a URI yet
declare -a builds=(
  "nixos__cmpkgs"
  #"nixos_19_03__606306e0eaacdaba1d3ada33485ae4cb413faeb5"
  #"nixos_unstable__4ab1c14714fc97a27655f3a6877386da3cb237bc"
)

for brev in "${builds[@]}"; do
  build "${brev}"
done

for brev in "${builds[@]}"; do
  url="$(./mkimage.sh \
    upload \
    "result/${brev}/disk.vhd" \
    "$(cat "result/${brev}_name")")"

  echo "${brev}: ${url}"
done

