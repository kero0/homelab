{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.apcupsd = {
    enable = true;
  };
}
