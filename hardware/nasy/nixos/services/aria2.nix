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
      ariang =
        let
          ariang =
            with pkgs;

            buildNpmPackage rec {
              pname = "ariang";
              version = "1.3.13";

              src = fetchFromGitHub {
                owner = "mayswind";
                repo = "AriaNg";
                tag = version;
                hash = "sha256-u4MnjGMvnnb9EGHwK2QYpW7cuX1e1+6z2/1X1baR8iA=";
              };

              npmDepsHash = "sha256-kxoSEdM8H7M9s6U2dtCdfuvqVROEk35jAkO7MgyVVRg=";

              makeCacheWritable = true;

              nodejs = nodejs_22;

              nativeBuildInputs = [
                copyDesktopItems
                imagemagick
              ];

              installPhase = ''
                runHook preInstall

                mkdir -p $out/share
                cp -r dist $out/share/${pname}

                for size in 16 24 36 48 72; do
                  mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
                  magick $out/share/${pname}/tileicon.png -resize ''${size}x''${size} \
                    $out/share/icons/hicolor/''${size}x''${size}/apps/${pname}.png
                done

                mkdir -p $out/bin
                makeWrapper ${xdg-utils}/bin/xdg-open $out/bin/${pname} \
                  --add-flags "file://$out/share/${pname}/index.html"

                runHook postInstall
              '';

              desktopItems = [
                (makeDesktopItem {
                  name = pname;
                  desktopName = "AriaNg";
                  genericName = meta.description;
                  comment = meta.description;
                  exec = pname;
                  icon = pname;
                  terminal = false;
                  type = "Application";
                  categories = [
                    "Network"
                    "WebBrowser"
                  ];
                })
              ];

              meta = {
                description = "Modern web frontend making aria2 easier to use";
                homepage = "http://ariang.mayswind.net/";
                license = lib.licenses.mit;
                maintainers = with lib.maintainers; [ stunkymonkey ];
                platforms = lib.platforms.unix;
              };
            };
        in
        mkContainer {
          containerConfig = {
            image = "docker.io/library/nginx:latest";
            volumes = [ "${ariang}/share/ariang:/usr/share/nginx/html:ro" ];
            labels = {
              "traefik.http.routers.ariang.rule" = "Host(`downloader.${mainaddr}`)";
              "traefik.http.services.ariang.loadbalancer.server.port" = "80";
            };
          };
        };
    };
  };
}
