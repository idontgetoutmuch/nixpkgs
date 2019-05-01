
let
  # TODO: should this move into azure-image and be the exported
  # function, then we can integrate the api for m-d-i options
  mkAzureImage = { nixpkgs, rev, extraModules?[], ... }:
  let
    pkgs = import (nixpkgs) {
      inherit (machine.config.nixpkgs) config overlays;
    };
    machine = import "${nixpkgs}/nixos/lib/eval-config.nix" {
      inherit pkgs;
      modules = [
        "${nixpkgs}/nixos/modules/virtualisation/azure-image.nix"
        ({config, ...}: {
          system.nixos.revision = rev;
          system.nixos.versionSuffix = ".git.${rev}";
        })
      ] ++ extraModules;
    };
  in
    {
      imageName = "nixos-image-${machine.config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.vhd";
      image = machine.config.system.build.azureImage;
      toplevel = machine.config.system.build.toplevel;
    };
in rec {
  # export the function so others can use it:
  inherit mkAzureImage;

  # nixos images:
  nixos__cmpkgs = mkAzureImage rec {
    rev = "cmpkgs3";
    url = "";
    nixpkgs = /root/code/nixpkgs;
  };

  nixos_unstable__4ab1c14714fc97a27655f3a6877386da3cb237bc = mkAzureImage rec {
    rev = "4ab1c14714fc97a27655f3a6877386da3cb237bc";
    url = "https://nixos0westus2aff271ee.blob.core.windows.net/vhds/nixos-image-19.09.git.4ab1c14714fc97a27655f3a6877386da3cb237bc-x86_64-linux.vhd";
    nixpkgs = builtins.fetchTarball {
      url = "https://github.com/nixos/nixpkgs/archive/${rev}.tar.gz";
      sha256 = "16lcj9552q2jfxc27j6116qkf2vl2dcj7vhg5gdq4qi51d891yhn";
    };
  };

  nixos_19_03__606306e0eaacdaba1d3ada33485ae4cb413faeb5 = mkAzureImage rec {
    rev = "606306e0eaacdaba1d3ada33485ae4cb413faeb5";
    url = "https://nixos0westus2aff271ee.blob.core.windows.net/vhds/nixos-image-19.03pre-git-x86_64-linux.vhd";
    nixpkgs = builtins.fetchTarball {
      url = "https://github.com/nixos/nixpkgs/archive/${rev}.tar.gz";
      sha256 = "06c10c5ayxjhim4c5a3xf3f71g3alklf7wh8lnp1vr5qr6kw4ci7";
    };
  };
}

