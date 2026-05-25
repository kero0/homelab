{
  lib,
  config,
  pkgs,
  mainaddr,
  configdir,
  sharesdir,
  ...
}:
let
  inherit (config.virtualisation.quadlet)
    containers
    builds
    ;
  mkContainer = lib.recursiveUpdate {
    unitConfig = {
      Requires = [ containers.vpn.ref ];
      After = [ containers.vpn.ref ];
    };
    containerConfig = {
      environments = {
        TZ = config.time.timeZone;
      };
      autoUpdate = "registry";
      logDriver = "journald";
      networks = [
        "container:vpn"
      ];
      labels."traefik.docker.network" = "vpn";
    };
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "30s";
    };
  };
in
{
  virtualisation.quadlet = {
    builds.aria2.buildConfig.file =
      (pkgs.writeText "Containerfile" ''
        FROM docker.io/library/alpine:latest
        RUN apk update && apk add --no-cache --update aria2
        ENTRYPOINT [ "aria2c", "--conf-path=/config/aria2.conf" ]
      '').outPath;
    containers = {
      aria2 = mkContainer {
        containerConfig = {
          image = builds.aria2.ref;
          volumes = [
            "${sharesdir}/Downloads:/downloads:rw"
            "${sharesdir}/Games:/games:rw"
            "${sharesdir}/Movies:/movies:rw"
            "${sharesdir}/Other:/other:rw"
            "${sharesdir}/TV:/tv:rw"
            "${configdir}/aria2-config:/config:rw"
          ];
          labels = {
            "traefik.http.services.aria2.loadbalancer.server.port" = "6800";
          };
        };
      };
      ariang = mkContainer {
        containerConfig = {
          image = "docker.io/library/nginx:latest";
          volumes = [ "${pkgs.ariang}/share/ariang:/usr/share/nginx/html:ro" ];
          labels = {
            "traefik.http.routers.ariang.rule" = "Host(`downloader.${mainaddr}`)";
            "traefik.http.services.ariang.loadbalancer.server.port" = "80";
          };
        };
      };
    };
  };
}
