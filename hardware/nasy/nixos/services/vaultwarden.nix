{
  config,
  mainaddr,
  lib,
  sharesdir,
  configdir,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers;
in
{
  virtualisation.quadlet.containers = {
    vaultwarden = {
      autoStart = true;
      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";
      };
      containerConfig = {
        image = "docker.io/vaultwarden/server:latest";
        environments = {
          DOMAIN = "https://vaultwarden.${mainaddr}";
        };
        volumes = [
          "${configdir}/vaultwarden:/data:rw"
        ];
        labels = {
          "traefik.http.routers.vaultwarden.rule" = "Host(`vaultwarden.${mainaddr}`)";
          "traefik.http.services.vaultwarden.loadbalancer.server.port" = "80";
        };
        logDriver = "journald";
      };
    };
    vaultwarden_backup = {
      autoStart = true;
      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";
      };
      unitConfig = {
        Requires = [
          containers.vaultwarden.ref
        ];
        After = [
          containers.vaultwarden.ref
        ];
      };
      containerConfig = {
        image = "docker.io/ttionya/vaultwarden-backup:latest";
        environments = {
          BACKUP_FILE_SUFFIX = "%s-%Y%m%d-%H%M%S";
          BACKUP_KEEP_DAYS = "100";
          CRON = "5 0 * * *";
          RCLONE_REMOTE_DIR = "/";
          RCLONE_REMOTE_NAME = "BitwardenBackup";
          TIMEZONE = config.time.timeZone;
          ZIP_ENABLE = "FALSE";
        };
        volumes = [
          "${configdir}/vaultwarden:/bitwarden/data:ro"
          "${configdir}/vaultwarden-rclone:/config:rw"
        ];
        labels = {
          "traefik.enable" = "false";
        };
        logDriver = "journald";
      };
    };
  };
}
