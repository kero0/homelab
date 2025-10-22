{
  lib,
  config,
  mainaddr,
  configdir,
  sharesdir,
  ...
}:
{
  virtualisation.oci-containers.containers.metube = {
    image = "ghcr.io/alexta69/metube";
    environment = {
      "CREATE_CUSTOM_DIRS" = "true";
      "CUSTOM_DIRS" = "true";
      "DELETE_FILE_ON_TRASHCAN" = "false";
      "OUTPUT_TEMPLATE" = "%(title)s [%(id)s].%(ext)s";
      "PGID" = "${toString config.users.groups.services.gid}";
      "PUID" = "${toString config.users.users.serviceuser.uid}";
      "STATE_DIR" = "/config";
      "TZ" = config.time.timeZone;
      "YTDL_OPTIONS" = builtins.toJSON {
        "extractor_args" = {
          "generic" = [ "impersonate" ];
        };
        "cookiefile" = "/downloads/cookies/cookies.txt";
      };
    };
    volumes = [
      "${sharesdir}/metube:/downloads:rw"
      "${configdir}/metube:/config:rw"
    ];
    labels = {
      "traefik.docker.network" = "vpn";
      "traefik.http.services.metube.loadbalancer.server.port" = "8081";
    };
    dependsOn = [
      "vpn"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network=container:vpn"
    ];
  };
}
