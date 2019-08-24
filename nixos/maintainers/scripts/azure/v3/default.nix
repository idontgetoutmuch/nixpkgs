let
  mkAzureImage = (import ../../../../modules/virtualisation/azure-mkimage.nix).mkAzureImage;
in
  (mkAzureImage rec {
    rev = "latest0"; # TODO: fix this?
    nixpkgs = ../../../../..;
  }).machine.config.system.build.azureImage
