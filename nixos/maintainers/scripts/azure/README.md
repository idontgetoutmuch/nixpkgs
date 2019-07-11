# nixos/azure

### Usage

#### Create & Upload "Official" Images

1. Update `./azure-images-src.nix`, as appropriate.
2. From `<nixpkgs>/nixos/maintainers/scripts/azure`, run `./images-ensure.vhd`. This will ensure all images are built and re-upload them all.
3. You should manually update `azure-images.nix` with the uploaded image URLs.

```bash
nvim ./../../../modules/virtualisation/azure-images.nix
./az.sh login # as needed
./images-ensure.vhd
```


#### Booting Image

Pick an image from `../../../modules/virtualisation/azure-images.nix`.

Use like so:

```bash
./az.sh login # as needed

# Create an Azure Image in your subscription with given URL:
imgurl="https://nixos0westus2aff271ee.blob.core.windows.net/vhds/nixos-image-19.09.git.cmpkgs3-x86_64-linux.vhd" # from `azure-images.nix`
imageid="$(./mkimage.sh copy "${imgurl}")"

# or if you have already uploaded one in your subscription
imageid="/subscriptions/aff271ee-e9be-4441-b9bb-42f5af4cbaeb/resourceGroups/NIXOS_PRODUCTION/providers/Microsoft.Compute/images/nixos-image-19.09.git.cmpkgs3-x86_64-linux.vhd"

# Boot an Azure VM from your image:
./mkvm.sh "${imageid}"
```

`mkvm.sh` takes an Azure image id that looks like this: `/subscriptions/aff271ee-e9be-4441-b9bb-42f5af4cbaeb/resourceGroups/NIXOS_PRODUCTION/providers/Microsoft.Compute/images/nixos-image-19.09.git.cmpkgs3-x86_64-linux.vhd`. You only need to create an image once in your subscription (unless you need more replicas for high capacity reasons, etc).


#### Custom Image

`custom-image-example/` contains an example of a custom image.

### Background

These scripts are meant to be a one-stop shop.
* `./images-ensure.sh` is meant to be idempotent. It will ensure all images from `./azure-images-src.nix` are built and uploaded.
* `./mkimage.sh` is normally called by `./images-ensure`, but can also be used manually to upload an image or internal-to-Azure copy an existing image blob.
* `./mkvm.sh` takes an image id (as output by `./mkimage.sh`) and will boot a new Azure VM with decent-enough defaults to sanity check the image(s).

This functionality is these scripts is non-trivial. It handles:
1. creating *any and all* necessary missing resources
2. replicating the specified VHD blob to your own storage account/location
3. automatic unique naming per all of Azure's contraints: supports multi-region, multi-replica, multi-subscription magic, meaning it should "just work" out of the box, and the official account will be simply be official by naturing of living in the official NixOS storage account .

### TODO

1. Get `azure-cli` into nixpkgs properly and stop relying on `docker`.
2. Make `./images-ensure.sh` only uploads missing images.
3. fix the location name being part of the managed disk id
4. fix the output of mkimage.sh so that it can output the image id and the blob url (caller can pick what they need)


### NixOS Administrative Notes:

We should:

1. Make sure a few people have public Azure accounts.
2. Add them all to the RG that contains the SA, etc.
3. Make sure at least two people remember that (1) they have access, (2) their microsoft account logins.

