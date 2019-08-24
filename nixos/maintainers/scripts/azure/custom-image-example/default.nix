let
  rev = "2eaad3ec3e43a0cfa49ca6524c518c86eb7c34b5";
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/colemickens/nixpkgs/archive/${rev}.tar.gz";
    sha256 = "1nscn48k0y7d0jffcb948h2ps6z0vgdcswwwwdvy7hh69m2ryy17";
  };
  mkAzureImage = (import "${nixpkgs}/nixos/modules/virtualisation/azure-mkimage.nix").mkAzureImage;
in mkAzureImage {
  inherit nixpkgs;
  inherit rev;
  diskSize = 2048;
}
