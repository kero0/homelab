{
  pkgs,
  lib,
  config,
  mainaddr,
  configdir,
  sharesdir,
  ...
}:
{
  virtualisation.oci-containers.containers = {
    jellyfin = {
      image = "docker.io/jellyfin/jellyfin:latest";
      environment = {
        "JELLYFIN_PublishedServerUrl" = "media.${mainaddr}";
        "NVIDIA_VISIBLE_DEVICES" = "all";
        "TZ" = config.time.timeZone;
      };
      volumes = [
        "${sharesdir}/Movies:/media/Movies:rw"
        "${sharesdir}/Movies-Kids:/media/Movies-Kids:rw"
        "${sharesdir}/TV:/media/TV:rw"
        "${sharesdir}/TV-Kids:/media/TV-Kids:rw"
        "${configdir}/jellyfin:/config:rw"
        "jellyfin-cache:/cache:rw"
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
      dependsOn = [
        "vpn"
      ];
      user = "${toString config.users.users.serviceuser.uid}:${toString config.users.groups.services.gid}";
      log-driver = "journald";
      extraOptions = [
        "--device=/dev/dri:/dev/dri:rwm"
        "--device=nvidia.com/gpu=all"
        "--network=container:vpn"
      ];
    };
  };
}
