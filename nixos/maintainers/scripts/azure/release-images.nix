let
  mkAzureImage = (import ./azure-mkimage.nix);
in
  {
    nixos_1903_20190911_103149 = (mkAzureImage rec { # nixos-19.03 (Wed Sep 11 10:31:49 UTC 2019)
      rev = "8a30e242181410931bcd0384f7147b6f1ce286a2";
      nixpkgs = builtins.fetchTarball {
        url = "https://github.com/nixos/nixpkgs/archive/${rev}.tar.gz";
        sha256 = "0574zwcgy3pqjcxli4948sd3sy6h0qw6fvsm4r530gqj41gpwf6b";
      };
    });
  }
