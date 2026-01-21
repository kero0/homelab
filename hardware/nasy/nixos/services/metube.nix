{
  lib,
  config,
  mainaddr,
  configdir,
  sharesdir,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers;
in
{
  virtualisation.quadlet.containers.metube = {
    unitConfig = {
      Requires = [
        containers.vpn.ref
      ];
      After = [
        containers.vpn.ref
      ];
    };
    containerConfig = {
      image = "ghcr.io/alexta69/metube";
      environments = {
        CREATE_CUSTOM_DIRS = "true";
        CUSTOM_DIRS = "true";
        DELETE_FILE_ON_TRASHCAN = "false";
        OUTPUT_TEMPLATE = "%(title)s [%(id)s].%(ext)s";
        PGID = "${toString config.users.groups.services.gid}";
        PUID = "${toString config.users.users.serviceuser.uid}";
        STATE_DIR = "/config";
        TZ = config.time.timeZone;
        YTDL_OPTIONS = builtins.toJSON {
          extractor_args = {
            generic = [ "impersonate" ];
          };
          cookiefile = "/downloads/cookies/cookies.txt";
        };
      };
      volumes = [
        "${sharesdir}/metube:/downloads:rw"
        "${configdir}/metube:/config:rw"
      ];
      labels = {
        "traefik.docker.network" = "vpn";
        "traefik.http.services.metube.loadbalancer.server.port" = "8081";
        "traefik.http.routers.metube.middlewares" = "tinyauth";
        "tinyauth.apps.metube.oauth.groups" = "tertiary";
      };
      logDriver = "journald";
      networks = [
        "container:vpn"
      ];
    };
  };

}
