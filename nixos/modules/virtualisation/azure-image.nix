{ config, lib, pkgs, ... }:

with lib;
let
  diskSize = 1536;
in
{
  system.build.azureImage = import ../../lib/make-disk-image.nix {
    name = "azure-image";
    postVM = ''
      set -e
      export disk="$out/nixos-image-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.vhd"
      ${pkgs.vmTools.qemu}/bin/qemu-img convert -f raw -o subformat=fixed,force_size -O vpc $diskImage $disk
      rm -f $diskImage
      ln -s $disk $out/disk.vhd
    '';
    configFile = ./azure-config-user.nix;
    format = "raw";
    inherit diskSize;
    inherit config lib pkgs;
  };

  imports = [ ./azure-common.nix ];

  # Azure metadata is available as a CD-ROM drive.
  fileSystems."/metadata".device = "/dev/sr0";
  fileSystems."/" = {
    autoResize = true;
    fsType = "ext4";
  };

  boot.growPartition = true;
  services.udisks2.enable = false;

  systemd.services.fetch-ssh-keys =
    { description = "Fetch host keys and authorized_keys for root user";

      wantedBy = [ "sshd.service" "waagent.service" ];
      before = [ "sshd.service" "waagent.service" ];
      after = [ "local-fs.target" ];

      path  = [ pkgs.coreutils ];
      script =
        ''
          eval "$(cat /metadata/CustomData.bin)"
          if ! [ -z "$ssh_host_ecdsa_key" ]; then
            echo "downloaded ssh_host_ecdsa_key"
            echo "$ssh_host_ecdsa_key" > /etc/ssh/ssh_host_ed25519_key
            chmod 600 /etc/ssh/ssh_host_ed25519_key
          fi

          if ! [ -z "$ssh_host_ecdsa_key_pub" ]; then
            echo "downloaded ssh_host_ecdsa_key_pub"
            echo "$ssh_host_ecdsa_key_pub" > /etc/ssh/ssh_host_ed25519_key.pub
            chmod 644 /etc/ssh/ssh_host_ed25519_key.pub
          fi

          if ! [ -z "$ssh_root_auth_key" ]; then
            echo "downloaded ssh_root_auth_key"
            mkdir -m 0700 -p /root/.ssh
            echo "$ssh_root_auth_key" > /root/.ssh/authorized_keys
            chmod 600 /root/.ssh/authorized_keys
          fi
        '';
      serviceConfig.Type = "oneshot";
      serviceConfig.RemainAfterExit = true;
      serviceConfig.StandardError = "journal+console";
      serviceConfig.StandardOutput = "journal+console";
     };
}
