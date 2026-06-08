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

      templates.default = {
        frequently = 0;
        hourly = 36;
        daily = 30;
        weekly = 4;
        monthly = 12;
        yearly = 0;
        autosnap = true;
        autoprune = true;
      };
      datasets = lib.mkMerge (
        [ { "zroot/configs".useTemplate = [ "default" ]; } ]
        ++ map (share: { "zroot/Shares/${share}".useTemplate = [ "default" ]; }) config.my.backup-shares
      );
    };
  };
}
