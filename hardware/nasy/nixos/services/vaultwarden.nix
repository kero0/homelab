{
  config,
  mainaddr,
  lib,
  sharesdir,
  configdir,
  ...
}:
{
  virtualisation.oci-containers.containers = {
    vaultwarden = {
      image = "docker.io/vaultwarden/server:latest";
      environment = {
        "DOMAIN" = "https://vaultwarden.${mainaddr}";
      };
      volumes = [
        "${configdir}/vaultwarden:/data:rw"
      ];
      labels = {
        "traefik.http.routers.vaultwarden.rule" = "Host(`vaultwarden.${mainaddr}`)";
        "traefik.http.services.vaultwarden.loadbalancer.server.port" = "80";
      };
      log-driver = "journald";
    };
    vaultwarden_backup = {
      image = "docker.io/ttionya/vaultwarden-backup:latest";
      environment = {
        "BACKUP_FILE_SUFFIX" = "%s-%Y%m%d-%H%M%S";
        "BACKUP_KEEP_DAYS" = "100";
        "CRON" = "5 0 * * *";
        "RCLONE_REMOTE_DIR" = "/";
        "RCLONE_REMOTE_NAME" = "BitwardenBackup";
        "TIMEZONE" = config.time.timeZone;
        "ZIP_ENABLE" = "FALSE";
      };
      volumes = [
        "${configdir}/vaultwarden:/bitwarden/data:rw"
        "${configdir}/vaultwarden-rclone:/config:rw"
      ];
      labels = {
        "traefik.enable" = "false";
      };
      log-driver = "journald";
    };
  };
}
