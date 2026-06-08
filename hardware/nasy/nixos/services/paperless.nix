{
  lib,
  config,
  mainaddr,
  sharesdir,
  genericServiceUser,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers volumes;
  subdomain = "documents";
  url = "${subdomain}.${mainaddr}";
in
{
  services.samba.settings.Documents = {
    path = "${sharesdir}/Paperless/consume";
    "read only" = "no";
    browseable = "yes";
    "guest ok" = "yes";
    "create mask" = "0644";
    "directory mask" = "0755";
    "fruit:veto_appledouble" = "yes";
    "force user" = genericServiceUser.name;
    "force group" = genericServiceUser.group;
  };
  my.backup-shares = [ "Paperless" ];
  virtualisation.quadlet = {
    volumes = {
      paperless-broker = { };
      paperless-db = { };
    };
    containers = {
      paperless-broker.containerConfig = {
        image = "docker.io/library/redis:8";
        volumes = [
          "${volumes.paperless-broker.ref}:/data"
        ];
        labels = {
          "traefik.enable" = "false";
        };
      };
      paperless-db.containerConfig = {
        image = "docker.io/library/postgres:18";
        environments = {
          POSTGRES_DB = "paperless";
          POSTGRES_USER = "paperless";
          POSTGRES_PASSWORD = "paperless";
        };
        volumes = [
          "${volumes.paperless-db.ref}:/var/lib/postgresql"
        ];
        labels = {
          "traefik.enable" = "false";
        };
      };
      paperless = {
        unitConfig = {
          Requires = [
            containers.paperless-db.ref
            containers.paperless-broker.ref
            containers.gotenberg.ref
            containers.tika.ref
          ];
          After = [
            containers.paperless-db.ref
            containers.paperless-broker.ref
            containers.gotenberg.ref
            containers.tika.ref
          ];
        };
        containerConfig = {
          image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
          environments = {
            PAPERLESS_REDIS = "redis://paperless-broker:6379";
            PAPERLESS_DBHOST = "paperless-db";
            PAPERLESS_TIKA_ENABLED = "1";
            PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://gotenberg:3000";
            PAPERLESS_TIKA_ENDPOINT = "http://tika:9998";
            PAPERLESS_URL = "https://${url}";

            PAPERLESS_TIME_ZONE = config.time.timeZone;
            PAPERLESS_OCR_LANGUAGE = "eng";
            PAPERLESS_OCR_LANGUAGES = "eng ara equ";
            PAPERLESS_ENABLE_HTTP_REMOTE_USER = "true";
            PAPERLESS_HTTP_REMOTE_USER_HEADER_NAME = "HTTP_REMOTE_USER";
            PAPERLESS_DISABLE_REGULAR_LOGIN = "true";
          };
          volumes = [
            "${sharesdir}/Paperless/data:/usr/src/paperless/data"
            "${sharesdir}/Paperless/media:/usr/src/paperless/media"
            "${sharesdir}/Paperless/export:/usr/src/paperless/export"
            "${sharesdir}/Paperless/consume:/usr/src/paperless/consume"
          ];
          user = "${toString config.users.users.serviceuser.uid}:${toString config.users.groups.services.gid}";
          labels = {
            "traefik.http.routers.paperless.rule" = "Host(`${url}`)";
            "traefik.http.services.paperless.loadbalancer.server.port" = "8000";
            "traefik.http.routers.paperless.middlewares" = "tinyauth";
            "tinyauth.apps.${subdomain}.oauth.groups" = lib.mkIf (containers ? tinyauth) "documents";
          };
        };
      };
      gotenberg.containerConfig = {
        image = "docker.io/gotenberg/gotenberg:8.25";
        exec = [
          "gotenberg"
          "--chromium-disable-javascript=true"
          "--chromium-allow-list=file:///tmp/.*"
        ];
        labels = {
          "traefik.enable" = "false";
        };
      };
      tika.containerConfig = {
        image = "docker.io/apache/tika:latest";
        labels = {
          "traefik.enable" = "false";
        };
      };
    };
  };
}
