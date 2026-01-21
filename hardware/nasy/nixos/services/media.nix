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
  virtualisation.quadlet.containers = {
    qbittorrent = {
      unitConfig = {
        Requires = [
          containers.vpn.ref
        ];
        After = [
          containers.vpn.ref
        ];
      };
      containerConfig =
        let
          WEBUI_PORT = "8130";
        in
        {
          image = "docker.io/linuxserver/qbittorrent:latest";
          environments = {
            inherit WEBUI_PORT;
            PGID = "${toString config.users.groups.services.gid}";
            PUID = "${toString config.users.users.serviceuser.uid}";
            TZ = config.time.timeZone;
          };
          volumes = [
            "${sharesdir}/Downloads:/downloads:rw"
            "${sharesdir}/Games:/games:rw"
            "${sharesdir}/TV:/tv:rw"
            "${sharesdir}/Movies:/movies:rw"
            "${sharesdir}/Other:/other:rw"
            "${configdir}/qbittorrent:/config:rw"
          ];
          labels = {
            "traefik.docker.network" = "vpn";
            "traefik.http.routers.qbittorrent.rule" = "Host(`torrent.${mainaddr}`)";
            "traefik.http.services.qbittorrent.loadbalancer.server.port" = WEBUI_PORT;
            "traefik.http.routers.qbittorrent.middlewares" = "tinyauth";
            "tinyauth.apps.torrent.ip.bypass" = "10.88.0.0/16";
            "tinyauth.apps.torrent.oauth.groups" = "secondary";
          };
          logDriver = "journald";
          networks = [
            "container:vpn"
          ];
        };
    };
    jackett = {
      unitConfig = {
        Requires = [
          containers.vpn.ref
        ];
        After = [
          containers.vpn.ref
        ];
      };
      containerConfig = {
        image = "docker.io/linuxserver/jackett:latest";
        environments = {
          PGID = "${toString config.users.groups.services.gid}";
          PUID = "${toString config.users.users.serviceuser.uid}";
          TZ = config.time.timeZone;
        };
        volumes = [
          "${configdir}/jackett:/config:rw"
        ];
        labels = {
          "traefik.docker.network" = "vpn";
          "traefik.http.routers.jackett.rule" = "Host(`jackett.${mainaddr}`)";
          "traefik.http.services.jackett.loadbalancer.server.port" = "9117";
        };
        logDriver = "journald";
        networks = [
          "container:vpn"
        ];
      };
    };
    prowlarr = {
      unitConfig = {
        Requires = [
          containers.vpn.ref
        ];
        After = [
          containers.vpn.ref
        ];
      };
      containerConfig = {
        image = "docker.io/linuxserver/prowlarr:latest";
        environments = {
          PGID = "${toString config.users.groups.services.gid}";
          PUID = "${toString config.users.users.serviceuser.uid}";
          TZ = config.time.timeZone;
        };
        volumes = [
          "${configdir}/prowlarr:/config:rw"
        ];
        labels = {
          "traefik.docker.network" = "vpn";
          "traefik.http.routers.prowlarr.rule" = "Host(`prowlarr.${mainaddr}`)";
          "traefik.http.services.prowlarr.loadbalancer.server.port" = "9696";
        };
        logDriver = "journald";
        networks = [
          "container:vpn"
        ];
      };
    };
    flaresolverr = {
      containerConfig = {
        image = "ghcr.io/flaresolverr/flaresolverr:latest";
        environments = {
          PGID = "${toString config.users.groups.services.gid}";
          PUID = "${toString config.users.users.serviceuser.uid}";
          LOG_LEVEL = "info";
          LOG_HTML = "false";
          TZ = config.time.timeZone;
        };
        labels = {
          "traefik.http.routers.flaresolverr.rule" = "Host(`flaresolverr.${mainaddr}`)";
          "traefik.http.services.flaresolverr.loadbalancer.server.port" = "8191";
        };
        logDriver = "journald";
      };
    };
    sonarr-main = {
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
      containerConfig = {
        image = "docker.io/linuxserver/sonarr:latest";
        environments = {
          PGID = "${toString config.users.groups.services.gid}";
          PUID = "${toString config.users.users.serviceuser.uid}";
          TZ = config.time.timeZone;
        };
        volumes = [
          "${configdir}/sonarr:/config:rw"
          "${sharesdir}/Downloads:/downloads:rw"
          "${sharesdir}/TV:/tv:rw"
        ];
        labels = {
          "traefik.http.routers.sonarr-main.rule" = "Host(`sonarr.${mainaddr}`)";
          "traefik.http.services.sonarr-main.loadbalancer.server.port" = "8989";
          "traefik.http.routers.sonarr-main.middlewares" = "tinyauth";
          "tinyauth.apps.sonarr.oauth.groups" = "secondary";
        };
        logDriver = "journald";
      };
    };
    radarr-main = {
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
      containerConfig = {
        image = "docker.io/linuxserver/radarr:latest";
        environments = {
          PGID = "${toString config.users.groups.services.gid}";
          PUID = "${toString config.users.users.serviceuser.uid}";
          TZ = config.time.timeZone;
        };
        volumes = [
          "${configdir}/radarr:/config:rw"
          "${sharesdir}/Downloads:/downloads:rw"
          "${sharesdir}/Movies:/movies:rw"
        ];
        labels = {
          "traefik.http.routers.radarr-main.rule" = "Host(`radarr.${mainaddr}`)";
          "traefik.http.services.radarr-main.loadbalancer.server.port" = "7878";
          "traefik.http.routers.radarr-main.middlewares" = "tinyauth";
          "tinyauth.apps.radarr.oauth.groups" = "secondary";
        };
        logDriver = "journald";
      };
    };
    sonarr-kids = {
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
      containerConfig = {
        image = "docker.io/linuxserver/sonarr:latest";
        environments = {
          PGID = "${toString config.users.groups.services.gid}";
          PUID = "${toString config.users.users.serviceuser.uid}";
          TZ = config.time.timeZone;
        };
        volumes = [
          "${configdir}/sonarr-kids:/config:rw"
          "${sharesdir}/Downloads:/downloads:rw"
          "${sharesdir}/TV-Kids:/tv:rw"
        ];
        labels = {
          "traefik.http.routers.sonarr-kids.rule" = "Host(`sonarr-kids.${mainaddr}`)";
          "traefik.http.services.sonarr-kids.loadbalancer.server.port" = "8989";
          "traefik.http.routers.sonarr-kids.middlewares" = "tinyauth";
          "tinyauth.apps.sonarr-kids.oauth.groups" = "secondary";
        };
        logDriver = "journald";
      };
    };
    radarr-kids = {
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
        labels = {
          "traefik.http.routers.radarr-kids.rule" = "Host(`radarr-kids.${mainaddr}`)";
          "traefik.http.services.radarr-kids.loadbalancer.server.port" = "7878";
          "traefik.http.routers.radarr-kids.middlewares" = "tinyauth";
          "tinyauth.apps.radarr.oauth.groups" = "secondary";
        };
        logDriver = "journald";
      };
    };
  };
}
