# nixos/azure

This README should get you up and running with an "unofficial" or custom NixOS image on Azure.

There are scripts in this directory that automate this process. They are expected to work; this README is a best effort to document the process for other end users, or as a guide to adapt the scripts here for your own purposes.

Azure does not allow publishing public images without using their Marketplace. As such, NixOS will only upload images to a singular place, and then they can be replicated  TODO: Finish this boring text.

## Overiew

1. Create a blank managed disk.
2. Grab the access token for it.
3. Populate the disk:
   * Via a blob upload of a custom image.
   * Via replicating an "unofficial" published image.
4. (Optional) Create a Shared Image Gallery for use in your subscription to replicate the managed disk to all locations.

This README will guide you through that process.

Additionally, there are scripts in this directory that automate this process.

#### Considerations

1. `./az.sh` is used throughout, as it is a script that wraps the invocation of Azure CLI through Docker.
2. `azcopy` is also necessary. See [\[Azure/azure-cli#10192\]](https://github.com/Azure/azure-cli/issues/10192) for some details. It is packaged in nixpkgs.

## Create Image

1. Setup:
    ```bash
    group="nixosvhds"     # target resource group
    diskname="nixosDisk1" # disk name
    size="50"             # disk size in GB
    location="westus2"    # (mostly unimportant due to SIG replication)

    ./az.sh login
    ./az.sh group create \
      --name "${group}" \
      --location "${location}"
    ```

2. Create the Managed Disk for upload:
    ```bash
    ./az.sh disk create \
      --resource-group "${group}" \
      --name "${diskname}" \
      --size-gb "${size}" \
      --for-upload true
    ```
 
3. Create a SAS URL for the blob backing the Managed Disk:
    ```bash
    timeout=$(( 60 * 60 )) # disk access token timeout
    sasurl="$(\
      ./az.sh disk grant-access \
        --access-level Write \
        --resource-group "${group}" \
        --name "${diskname}" \
        --duration-in-seconds ${timeout} \
          | jq -r '.accessSas'
    )"
    ```

4. Populate the Managed Disk in one of two ways:
   * Upload a new VHD
      ```bash
      vhd="$(nix-build -A azure-vhd ...)" # TODO: flesh this out
      
      azcopy copy "${vhd}" "${sasurl}" \
        --blob-type PageBlob
      ```
   *  Replicate an existing image 
      ```bash
      url="https://nixosprdctvhds.blob.core.windows.net/vhds/production.vhd" # TODO: real example
    
      azcopy copy "${url}" "${sasurl}" \
        --blob-type PageBlob
      ```

5. Revoke the disk SAS token
    ```bash
    ./az.sh disk revoke-access \
       --resource-group "${group}" \
       --name "${diskname}"
    ```

6. Create an "image" from the managed disk
    ```bash
    diskid="$(./az.sh disk show -g "${group}" -n "${diskname}" -o json | jq -r .id)"
 
    ./az.sh image create \
      --resource-group "${group}" \
      --name "${diskname}" \
      --source "${diskid}" \
      --os-type "linux"
    ```

## Create SIG Image

This step lets you replicate your managed disk to all locations via an Azure **Shared Image Gallery**.

1. Setup/Config
    ```bash
    gallery="nixosvhds"
 
    publisher="publisher"
    offer="offer"
    sku="sku"
    
    sig_imagename="nixos"
    sig_version="1.0.0"

    imageid="$(./az.sh image show -g "${group}" -n "${diskname}" -o json | jq -r .id)"
    ```

2. Create the Shared Image Gallery if you have not already:
    ```bash
    ./az.sh sig create \
      --resource-group "${group}" \
      --gallery-name "${gallery}"
    ```

3. Create the SIG Image Definition
    ```bash
    ./az.sh sig image-definition create \
      --resource-group "${group}" \
      --gallery-name "${gallery}" \
      --gallery-image "${sig_imagename}" \
      --publisher "${publisher}" \
      --offer "${offer}" \
      --sku "${sku}" \
      --os-type "linux"
    ```

4. Replicate the disk image as an instance of the image definition in the Shared Image Gallery: 
    ```bash 
    ./az.sh sig image-version create \
      --resource-group "${group}" \
      --gallery-name "${gallery}" \
      --gallery-image-definition "${sig_imagename}" \
      --gallery-image-version "${sig_imageversion}" \
      --target-regions "WestCentralUS" "WestUS2" "WestUS" \
      --replica-count 2 \
      --managed-image "${imageid}"
 
    # TODO: why is there no refernce to the SKU?
    ```

## Test it Out!

Boot a new VM from your custom SIG Image:
  ```bash
  ./az.sh vm create \
    ...
  ```

### TODO

1. WTF are `publisher` / `offer` / `sku`? can we just set all to `"nixos"`? maybe `sku/offer="19.03"` and then we can push new versions of images

2. Make a script that just ingests the most recent released image in Azure to a
new or existing SIG in the user's subscription, all in one go.

3. `azcopy` package should have the binary as `azcopy` rather than `azure-storage-azcopy`.