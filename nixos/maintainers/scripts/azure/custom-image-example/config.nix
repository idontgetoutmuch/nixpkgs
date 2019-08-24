{ modulePath, config, pkgs, ... }:

with pkgs.lib;
{
    imports = [
      "${modulePath}/virtualisation/azure-common.nix"
    ];
  config = {
    
    services.openssh.permitRootLogin = "no";
    security.sudo.wheelNeedsPassword = false;
    networking.usePredictableInterfaceNames = lib.mkForce true;
  };
}
