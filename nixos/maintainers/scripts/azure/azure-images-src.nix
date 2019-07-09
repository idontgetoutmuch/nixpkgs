let
  mkAzureImage = (import ../../../modules/virtualisation/azure-mkimage.nix).mkAzureImage;
in rec {
  nixos_19_03__9ec7625cee5365c741dee7b45a19aff5d5d56205 = mkAzureImage rec {
    rev = "9ec7625cee5365c741dee7b45a19aff5d5d56205";
    nixpkgs = builtins.fetchTarball {
      url = "https://github.com/nixos/nixpkgs/archive/${rev}.tar.gz";
      sha256 = "0rh26fhdvnp9ssk8g63ysyzigw9zg43k9bd2fzrvhrk75sav723h";
    };
  };
}
