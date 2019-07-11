let
  mkAzureImage = {
    nixpkgs,
    rev,
    configFile ? "${nixpkgs}/nixos/modules/virtualisation/azure-config-user.nix",
    diskSize?1536,
    ... 
  }:
  let
    shortRev = builtins.substring 0 7 rev;
    pkgs = import (nixpkgs) {
      inherit (machine.config.nixpkgs) config overlays;
    };
    machine = import "${nixpkgs}/nixos/lib/eval-config.nix" {
      modules = [ configFile ] ++ [
        ({config, ...}: {
          system.nixos.revision = rev;
          system.nixos.versionSuffix = ".git.${shortRev}";
        })
        ({config, ...}: {
          system.build.azureImage = import ../../lib/make-disk-image.nix {
            name = "azure-image";
            postVM = ''
              export disk="$out/nixos-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.vhd"
              ${pkgs.vmTools.qemu}/bin/qemu-img convert -f raw -o subformat=fixed,force_size -O vpc $diskImage $disk
              rm -f $diskImage
              ln -s $disk $out/disk.vhd
            '';
            configFile = configFile;
            format = "raw";
            inherit diskSize;
            inherit config pkgs; inherit (pkgs) lib;
          };
        })
      ];
    };
  in {
    name = "nixos-${machine.config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.vhd";
    machine = machine;
  };
in
{
  mkAzureImage = mkAzureImage;
}
