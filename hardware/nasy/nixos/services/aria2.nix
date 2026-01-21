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
    networks
    pods
    ;
in
{
  virtualisation.quadlet = {
    builds.aria2.buildConfig.file =
      (pkgs.writeText "Containerfile" ''
        FROM docker.io/library/alpine:latest
        RUN apk update && apk add --no-cache --update aria2
        ENTRYPOINT [ "aria2c", "--conf-path=/config/aria2.conf" ]
      '').outPath;
    containers.aria2.containerConfig = {
      image = builds.aria2.ref;
      environments = {
        TZ = config.time.timeZone;
      };
      volumes = [
        "${sharesdir}/Downloads:/downloads:rw"
        "${sharesdir}/Games:/games:rw"
        "${sharesdir}/Movies:/movies:rw"
        "${sharesdir}/Other:/other:rw"
        "${sharesdir}/TV:/tv:rw"
        "${configdir}/aria2-config:/config:rw"
      ];
      labels = {
        "traefik.docker.network" = "vpn";
        "traefik.http.services.aria2.loadbalancer.server.port" = "6800";
      };
      logDriver = "journald";
      networks = [
        "container:vpn"
      ];
    };

    containers.ariang.containerConfig = {
      image = "docker.io/library/nginx:latest";
      volumes =
        let
          src' = builtins.fetchurl {
            url = "https://github.com/mayswind/AriaNg/releases/download/1.3.11/AriaNg-1.3.11-AllInOne.zip";
            sha256 = "0ax4l3ya62jw657qwvcrjqizkj6344syf94m61z5rwv1d0b87gmk";
          };
          src = pkgs.runCommand "ariang-src" { } ''
            mkdir -p $out
            ${pkgs.unzip}/bin/unzip ${src'} -d $out
          '';
          conf = pkgs.writeText "nginx.conf" ''
            user nginx nginx;
            daemon off;
            events {}
            http {
              server {
                listen 80;
                location / {
                  root /app/;
                }
              }
            }
          '';
        in
        [
          "${src}:/usr/share/nginx/html:ro"
        ];
      labels = {
        "traefik.docker.network" = "vpn";
        "traefik.http.routers.ariang.rule" = "Host(`downloader.${mainaddr}`)";
        "traefik.http.services.ariang.loadbalancer.server.port" = "80";
        "traefik.http.routers.ariang.middlewares" = "tinyauth";
        "tinyauth.apps.downloader.oauth.groups" = "main";
      };
      logDriver = "journald";
      networks = [
        "container:vpn"
      ];
    };
  };
}
