{
  config,
  lib,
  myuser,
  ...
}:
{
  catppuccin.enable = lib.mkForce false;

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = false;
    initrd.availableKernelModules = [
      "virtio_pci"
      "virtio_scsi"
      "virtio_net"
      "ahci"
      "sd_mod"
      "xhci_pci"
    ];
    kernelParams = [
      "console=tty1"
      "console=ttyAMA0,115200"
    ];

  };
  networking = {
    useDHCP = false;
    useNetworkd = true;
  };
  systemd.network.networks."10-uplink" = {
    matchConfig.Type = "ether";
    networkConfig.DHCP = "ipv4";
  };

  services.fail2ban.enable = true;

  users.users.root.openssh.authorizedKeys.keys =
    config.users.users.${myuser}.openssh.authorizedKeys.keys;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
