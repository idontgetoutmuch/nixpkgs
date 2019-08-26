let
  mkAzureImage = (import ../../../../modules/virtualisation/azure-mkimage.nix).mkAzureImage;
in
  (mkAzureImage rec {
    rev = "latest0"; # TODO: fix this?
    nixpkgs = ../../../../..;
    # custom config with sudo adjusted, maybe?
    # custom config with wireguard enabled, for example
  }).machine.config.system.build.azureImage
