let
  mkAzureImage = (import ../../../modules/virtualisation/azure-mkimage.nix).mkAzureImage;
in rec {
  nixos_19_03__606306e0eaacdaba1d3ada33485ae4cb413faeb5 = mkAzureImage rec {
    rev = "606306e0eaacdaba1d3ada33485ae4cb413faeb5";
    nixpkgs = builtins.fetchTarball {
      url = "https://github.com/nixos/nixpkgs/archive/${rev}.tar.gz";
      sha256 = "06c10c5ayxjhim4c5a3xf3f71g3alklf7wh8lnp1vr5qr6kw4ci7";
    };
  };
}
