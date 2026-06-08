{ config, lib, ... }:
{
  age.secrets.syncoid-key = {
    owner = config.users.users.syncoid.name;
    group = config.users.groups.syncoid.name;
  };
  services.syncoid = {
    enable = true;
    commonArgs = [
      "--no-sync-snap"
      "--recursive"
      "--use-hold"
      "--sshport=9639"
      "--delete-target-snapshots"
    ];
    sshKey = config.age.secrets.syncoid-key.path;
    interval = "*-*-* 3:15:00";
    commands =
      let
        inherit (lib) mkMerge;
        inherit (builtins) map attrNames;
        inherit (config.networking) hostName;
      in
      mkMerge (
        map (name: {
          ${name} = {
            source = name;
            target = "root@209.209.10.60:storage/backups/${
              lib.replaceStrings [ "/" ] [ "__" ] "${hostName}//${name}"
            }";
            sendOptions = "w";
          };
        }) (attrNames config.services.sanoid.datasets)
      );
  };
}
