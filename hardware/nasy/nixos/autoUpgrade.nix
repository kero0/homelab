{ config, ... }:
{
  my.autoUpgrade = {
    enable = true;
    allowReboot = true;
  };
  system.autoUpgrade.flake = "github:kero0/homelab#${config.networking.hostName}";
}
