# nixos/azure

This README should get you up and running with an "unofficial" or custom NixOS image on Azure.

## Overiew

The full process for uploading a custom image, with replication, to Azure roughly looks like this:

1. Create a blank managed disk.
2. Grab the access token for it.
3. Populate the disk:
   * Via a blob upload of a custom image.
   * Via replicating an "unofficial" published image.
4. (Optional) Create a Shared Image Gallery for use in your subscription to replicate the managed disk to all locations.

The scripts in this directory automate this and require only a couple of steps in ideal conditions.

#### Considerations

1. `./az.sh` is a script that wraps `azure-cli`. The Azure CLI is not currently able to be packaged with `pypi2nix` (see: [\[Azure/azure-cli#10232\]](https://github.com/Azure/azure-cli/issues/10232)).
2. `azcopy` is also necessary. See [\[Azure/azure-cli#10192\]](https://github.com/Azure/azure-cli/issues/10192) for some details. It is packaged in nixpkgs as `azure-storage-azcopy`.

You'll want to have all of these installed: `jq`, `azure-storage-azcopy`, `docker`.

## **Usage**: End Users

#### Released URLs:

* **`nixos-19.03` on 2019-09-11**: `https://md-mr3x0kwh0vs4.blob.core.windows.net/d53pr4j5kkjv/abcd?sv=2017-04-17&sr=b&si=deacae49-c3b9-4876-b6cf-72ebcdf43bfa&sig=bpkCqnAV993C5t%2BkXM1JoOCcRh2Bl6BUaciT4Ejs4Qc%3D`

### Create From Released Image
```bash
source="[select URL from above]"
imagename="nixos_1903_20190911_103149"
azimage="$(./create-image.sh "${imagename}" "${source}"
azsigimage="$(./create-sig-image-version.sh "1.0.0" "${azimage}")"

# boot
./az.sh vm create \
  --name "testVM" \
  --resource-group "existingGroup" \
  --os-disk-size-gb "100" \
  --image "${azsigimage}" \
  --admin-username "${USER}" \
  --location "WestCentralUS" \
  --ssh-key-values "$(ssh-add -L)"
```

### Create From Custom Image
```bash
disk="$(./build-custom-vhd.sh)/disk.vhd"
azimage="$(./create-image.sh "nixos-${RANDOM}" "${disk}")"
azsigimage="$(./create-sig-image-version.sh "1.0.0" "${azimage}")"

# boot
./az.sh vm create \
  --name "testVM" \
  --resource-group "existingGroup" \
  --os-disk-size-gb "100" \
  --image "${azsigimage}" \
  --admin-username "${USER}" \
  --location "WestCentralUS" \
  --ssh-key-values "$(ssh-add -L)"
```

## **Usage**: Maintainers

### Upload a new Release Image
```bash
# edit the release-images.nix to add a new official release image
nvim ./release-images.nix

# use the new image name in this step:
image="nixos_1903_20190911_103149"
disk="$(./build-release-vhd.sh "${image}")/disk.vhd"
azimage="$(./create-image.sh "${image}" "${disk}")"
# (we don't need a private SIG Image for a release image, so skip it)

# test the released image
./az.sh vm create \
  --name "testVM" \
  --resource-group "existingGroup" \
  --os-disk-size-gb "100" \
  --image "${azimage}" \
  --admin-username "${USER}" \
  --location "westus2" \
  --ssh-key-values "$(ssh-add -L)"

# get a URL that is valid for 10 years, used for publishing releases:
./az.sh disk grant-access \
  --resource-group nixosvhds \
  --name "${image}" \
  --duration-in-seconds "$(( 365 * 24 * 60 * 60 ))"
```
