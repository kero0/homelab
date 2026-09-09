{
  lib,
  config,
  configdir,
  sharesdir,
  mkTraefikLabels,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers;
  mkContainer = lib.recursiveUpdate {
    unitConfig = {
      Requires = [ containers.vpn.ref ];
      After = [ containers.vpn.ref ];
    };
    containerConfig = {
      environments = {
        TZ = config.time.timeZone;
        PGID = "${toString config.users.groups.services.gid}";
        PUID = "${toString config.users.users.serviceuser.uid}";
      };
      autoUpdate = "registry";
      logDriver = "journald";
    };
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "30s";
    };
  };
  mkLeafContainer = lib.recursiveUpdate (mkContainer {
    unitConfig = {
      Requires = [
        containers.qbittorrent.ref
        containers.jackett.ref
        containers.prowlarr.ref
      ];
      After = [
        containers.qbittorrent.ref
        containers.jackett.ref
        containers.prowlarr.ref
      ];
    };
  });
in
{
  virtualisation.quadlet = {
    containers = {
      qbittorrent = mkContainer {
        containerConfig =
          let
            WEBUI_PORT = "8130";
          in
          {
            image = "docker.io/linuxserver/qbittorrent:latest";
            environments = {
              inherit WEBUI_PORT;
            };
            volumes = [
              "${sharesdir}/Downloads:/downloads:rw"
              "${sharesdir}/Games:/games:rw"
              "${sharesdir}/TV:/tv:rw"
              "${sharesdir}/Movies:/movies:rw"
              "${sharesdir}/Other:/other:rw"
              "${configdir}/qbittorrent:/config:rw"
            ];
            labels = mkTraefikLabels {
              subdomain = "torrent";
              application = "qbittorrent";
              port = WEBUI_PORT;
              public = true;
              vpn = true;
            };
            networks = [ "container:vpn" ];
          };
      };
      jackett = mkContainer {
        containerConfig = {
          image = "docker.io/linuxserver/jackett:latest";
          volumes = [
            "${configdir}/jackett:/config:rw"
          ];
          labels = mkTraefikLabels {
            subdomain = "jackett";
            port = 9117;
            vpn = true;
            oauth-groups = "admin";
          };
          logDriver = "journald";
          networks = [ "container:vpn" ];
        };
      };
      prowlarr = mkContainer {
        containerConfig = {
          image = "docker.io/linuxserver/prowlarr:latest";
          volumes = [
            "${configdir}/prowlarr:/config:rw"
          ];
          labels = mkTraefikLabels {
            subdomain = "prowlarr";
            port = 9696;
            vpn = true;
            oauth-groups = "admin";
          };
          networks = [ "container:vpn" ];
        };
      };
      flaresolverr = mkContainer {
        containerConfig = {
          image = "ghcr.io/flaresolverr/flaresolverr:latest";
          environments = {
            LOG_LEVEL = "info";
            LOG_HTML = "false";
          };
          labels = mkTraefikLabels {
            subdomain = "flaresolverr";
            port = 8191;
          };
        };
      };
      sonarr-main = mkLeafContainer {
        containerConfig = {
          image = "docker.io/linuxserver/sonarr:latest";
          volumes = [
            "${configdir}/sonarr:/config:rw"
            "${sharesdir}/Downloads:/downloads:rw"
            "${sharesdir}/TV:/tv:rw"
          ];
          labels = mkTraefikLabels {
            subdomain = "sonarr";
            application = "sonarr-main";
            port = 8989;
            oauth-groups = "secondary";
            public = true;
          };
        };
      };
      radarr-main = mkLeafContainer {
        containerConfig = {
          image = "docker.io/linuxserver/radarr:latest";
          volumes = [
            "${configdir}/radarr:/config:rw"
            "${sharesdir}/Downloads:/downloads:rw"
            "${sharesdir}/Movies:/movies:rw"
          ];
          labels = mkTraefikLabels {
            subdomain = "radarr";
            application = "radarr-main";
            port = 7878;
            oauth-groups = "secondary";
            public = true;
          };
        };
      };
      sonarr-kids = mkLeafContainer {
        containerConfig = {
          image = "docker.io/linuxserver/sonarr:latest";
          volumes = [
            "${configdir}/sonarr-kids:/config:rw"
            "${sharesdir}/Downloads:/downloads:rw"
            "${sharesdir}/TV-Kids:/tv:rw"
          ];
          labels = mkTraefikLabels {
            subdomain = "sonarr-kids";
            application = "sonarr-kids";
            port = 8989;
            oauth-groups = "secondary";
            public = true;
          };
        };
      };
      radarr-kids = mkLeafContainer {
        containerConfig = {
          image = "docker.io/linuxserver/radarr:latest";
          environments = {
            PGID = "${toString config.users.groups.services.gid}";
            PUID = "${toString config.users.users.serviceuser.uid}";
            TZ = config.time.timeZone;
          };
          volumes = [
            "${configdir}/radarr-kids:/config:rw"
            "${sharesdir}/Downloads:/downloads:rw"
            "${sharesdir}/Movies-Kids:/movies:rw"
          ];
          labels = mkTraefikLabels {
            subdomain = "radarr-kids";
            application = "radarr-kids";
            port = 7878;
            oauth-groups = "secondary";
            public = true;
          };
        };
      };
    };
  };
}
