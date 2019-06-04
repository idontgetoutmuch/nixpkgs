let
  rev = "2eaad3ec3e43a0cfa49ca6524c518c86eb7c34b5";
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/colemickens/nixpkgs/archive/${rev}.tar.gz";
    sha256 = "06c10c5ayxjhim4c5a3xf3f71g3alklf7wh8lnp1vr5qr6kw4ccc";
  };
  mkAzureImage = (import "${nixpkgs}/nixos/modules/virtualisation/azure-mkimage.nix").mkAzureImage;
in mkAzureImage {
  inherit nixpkgs;
  inherit rev;
  configFile = ./config.nix;
  diskSize = 2048;
}
