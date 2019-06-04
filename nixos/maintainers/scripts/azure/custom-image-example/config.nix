{ modulePath, config, pkgs, ... }:

with lib;
{
  config = {
    imports = [
      "${modulePath}/virtualisation/azure-common.nix"
    ];
    
    services.openssh.permitRootLogin = "no";
    security.sudo.wheelNeedsPassword = false;
    networking.usePredictableInterfaceNames = lib.mkForce true;
  };
}
