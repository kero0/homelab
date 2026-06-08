{
  pkgs,
  config,
  myuser,
  ...
}:
{
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  services.openssh.enable = true;
  services.fail2ban.enable = true;

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_stable;
  users.users.${myuser}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMvDP88rn/X7FE59zFrtk4e/js1JzAHsC5OUyGmDyV2J"
  ];
  users.users.root.openssh.authorizedKeys.keys =
    config.users.users.${myuser}.openssh.authorizedKeys.keys;
  environment.systemPackages = with pkgs; [
    # these are needed to be a syncoid target
    lzop
    mbuffer
  ];
}
