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
    volumes.booklore-mariadb = { };
    containers.booklore = {
      unitConfig = {
        Requires = [
          containers.booklore-mariadb.ref
        ];
        After = [
          containers.booklore-mariadb.ref
        ];
      };
      containerConfig = rec {
        image = "ghcr.io/booklore-app/booklore:latest";
        environments =
          let
            inherit (containers.booklore-mariadb.containerConfig.environments)
              MYSQL_DATABASE
              MYSQL_USER
              MYSQL_PASSWORD
              ;
          in
          {
            TZ = config.time.timeZone;
            DATABASE_URL = "jdbc:mariadb://booklore-mariadb:3306/${MYSQL_DATABASE}";
            DATABASE_USERNAME = MYSQL_USER;
            DATABASE_PASSWORD = MYSQL_PASSWORD;
            BOOKLORE_PORT = "6060";
            SWAGGER_ENABLED = "false";
            FORCE_DISABLE_OIDC = "false";

            REMOTE_AUTH_ENABLED = "true";
            REMOTE_AUTH_CREATE_NEW_USERS = "true";
            REMOTE_AUTH_HEADER_USER = config.my.auth-headers.user;
            REMOTE_AUTH_HEADER_NAME = config.my.auth-headers.name;
            REMOTE_AUTH_HEADER_EMAIL = config.my.auth-headers.email;
            REMOTE_AUTH_HEADER_GROUPS = config.my.auth-headers.groups;
            REMOTE_AUTH_ADMIN_GROUP = "admin";
            REMOTE_AUTH_GROUPS_DELIMITER = ",";

          };
        volumes = [
          "${sharesdir}/Books:/books:rw"
          "${sharesdir}/Bookdrop:/bookdrop:rw"
          "${configdir}/booklore:/app/data:rw"
        ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.services.booklore.loadbalancer.server.port" = environments.BOOKLORE_PORT;
          "traefik.http.routers.booklore.middlewares" = "tinyauth";
          "tinyauth.apps.booklore.oauth.groups" = "main";
        };
        logDriver = "journald";
      };
    };
    containers.booklore-mariadb = {
      containerConfig = {
        image = "lscr.io/linuxserver/mariadb:11.4.5";
        environments = {
          TZ = config.time.timeZone;
          MYSQL_ROOT_PASSWORD = "super_secure_password";
          MYSQL_DATABASE = "booklore";
          MYSQL_USER = "booklore";
          MYSQL_PASSWORD = "your_secure_password";
        };
        volumes = [
          "${volumes.booklore-mariadb.ref}:/config:rw"
        ];
        labels = {
          "traefik.enable" = "false";
        };
        logDriver = "journald";
      };
    };
  };
}
