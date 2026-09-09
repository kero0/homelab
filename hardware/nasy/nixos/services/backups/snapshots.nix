{
  config,
  lib,
  ...
}:
{
  options.my.backup-shares =
    with lib;
    mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  config = {
    services.sanoid = {
      enable = true;
      templates = {
        # timeshare already has a system for managing history
        Timeshare = {
          frequently = 0;
          hourly = 0;
          daily = 1;
          weekly = 0;
          monthly = 0;
          yearly = 0;
          autosnap = true;
          autoprune = true;
        };
        default = {
          frequently = 0;
          hourly = 36;
          daily = 30;
          weekly = 4;
          monthly = 12;
          yearly = 0;
          autosnap = true;
          autoprune = true;
        };
      };
      datasets = lib.mkMerge (
        [ { "zroot/configs".useTemplate = [ "default" ]; } ]
        ++ map (share: {
          "zroot/Shares/${share}".useTemplate = lib.lists.singleton (
            if config.services.sanoid.templates ? "${share}" then share else "default"
          );
        }) config.my.backup-shares
      );
    };
  };
}
