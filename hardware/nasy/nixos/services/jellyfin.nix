{
  pkgs,
  lib,
  config,
  mainaddr,
  configdir,
  sharesdir,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers volumes;
in
{
  virtualisation.quadlet = {
    volumes.jellyfin-cache = { };
    containers.jellyfin = {
      unitConfig = {
        Requires = [
          containers.vpn.ref
        ];
        After = [
          containers.vpn.ref
        ];
      };
      containerConfig = {
        image = "docker.io/jellyfin/jellyfin:latest";
        environments = {
          JELLYFIN_PublishedServerUrl = "media.${mainaddr}";
          NVIDIA_VISIBLE_DEVICES = "all";
          TZ = config.time.timeZone;
        };
        volumes = [
          "${sharesdir}/Movies:/media/Movies:rw"
          "${sharesdir}/Movies-Kids:/media/Movies-Kids:rw"
          "${sharesdir}/TV:/media/TV:rw"
          "${sharesdir}/TV-Kids:/media/TV-Kids:rw"
          "${configdir}/jellyfin:/config:rw"
          "${volumes.jellyfin-cache.ref}:/cache:rw"
        ];
        labels = {
          "traefik.docker.network" = "vpn";
          "traefik.http.middlewares.jellyfin.headers.STSIncludeSubdomains" = "true";
          "traefik.http.middlewares.jellyfin.headers.STSPreload" = "true";
          "traefik.http.middlewares.jellyfin.headers.contentTypeNosniff" = "true";
          "traefik.http.middlewares.jellyfin.headers.customResponseHeaders.X-Robots-Tag" =
            "noindex,nofollow,nosnippet,noarchive,notranslate,noimageindex";
          "traefik.http.middlewares.jellyfin.headers.customresponseheaders.X-XSS-PROTECTION" = "1";
          "traefik.http.middlewares.jellyfin.headers.forceSTSHeader" = "true";
          "traefik.http.middlewares.jellyfin.headers.frameDeny" = "true";
          "traefik.http.routers.jellyfin.middlewares" = "jellyfin";
          "traefik.http.routers.jellyfin.rule" = "Host(`media.${mainaddr}`)";
          "traefik.http.services.jellyfin.loadbalancer.server.port" = "8096";
        };
        user = "${toString config.users.users.serviceuser.uid}:${toString config.users.groups.services.gid}";
        logDriver = "journald";
        networks = [
          "container:vpn"
        ];
        devices = [
          "/dev/dri:/dev/dri:rwm"
          "nvidia.com/gpu=all"
        ];
      };
    };
  };

}
