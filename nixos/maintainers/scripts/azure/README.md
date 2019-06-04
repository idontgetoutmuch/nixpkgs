# nixos/azure

### Usage

#### Create & Upload "Official" Images

1. Update `<nixpkgs>/nixos/modules/virtualisation/azure-images.nix`, as appropriate.
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


### Background

This functionality is somewhat non-trivial. It handles:
1. creating *any and all* necessary missing resources
2. replicating the specified VHD blob to your own storage account/location
3. automatic unique naming per all of Azure's contraints: supports multi-region, multi-replica, multi-subscription magic, meaning it should "just work" out of the box, and the official account will be simply be official by naturing of living in the orificial NixOS storage account (identifiable by part of the storage account identifier which is present in the final VHD URI).)


### NixOS Administrative Notes:

We should:

1. Make sure a few people have public-dir Azure accounts.
2. Add them all to the RG that contains the SA, etc.
3. Make sure at least two people remember that (1) they have access, (2) their microsoft account logins.

