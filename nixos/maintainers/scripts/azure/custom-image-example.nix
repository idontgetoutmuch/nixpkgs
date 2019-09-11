let
  mkAzureImage = (import ./azure-mkimage.nix);
in
  (mkAzureImage rec {
    rev = "latest0"; # TODO: fix this?
    nixpkgs = ../../../..;
    # custom config with sudo adjusted, maybe?
    # custom config with wireguard enabled, for example
  })
