{ lib, pkgs, ... }:

with lib;
{
  imports = [ ./azure-common.nix ];

  services.openssh.permitRootLogin = "no";
  security.sudo.wheelNeedsPassword = false;
  networking.usePredictableInterfaceNames = lib.mkForce true;
}
