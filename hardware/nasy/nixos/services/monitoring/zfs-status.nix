{
  config,
  lib,
  pkgs,
  ...
}:
{
  systemd.services.my-zfs-status-ntfy = lib.mkIf config.services.ntfy-sh.enable {
    description = "Notify ZFS status";
    startAt = "*-*-* 6:15:00";
    path = with pkgs; [
      curl
      zfs
    ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "zfs-status-ntfy" ''
        username=zfs-status
        password=$(< ${config.age.secrets.ntfy-default-pass.path})
        url=${config.services.ntfy-sh.settings.base-url}/zfs-status
        if ! zpool status -x; then
           priority=max
           title="⚠️ ZFS status is NOT good on ${config.networking.hostName}"
           body=$(zpool status)
        else
           priority=min
           title="✅ ZFS status is good on ${config.networking.hostName}"
           body=$(zpool status)
        fi
        curl -X POST -u "$username:$password" \
            -H "Priority: $priority"          \
            -H "Title: $title"                \
            -d "$body"                        \
            "$url"
      '';
    };
  };
}
