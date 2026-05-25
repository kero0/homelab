{
  config,
  mainaddr,
  sharesdir,
  genericServiceUser,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers volumes;
  subdomain = "warranty";
  url = "${subdomain}.${mainaddr}";
in
{
  services.samba.settings.Warranties = {
    path = "${sharesdir}/Warracker/";
    "read only" = "no";
    browseable = "yes";
    "guest ok" = "yes";
    "create mask" = "0644";
    "directory mask" = "0755";
    "fruit:veto_appledouble" = "yes";
    "force user" = genericServiceUser.name;
    "force group" = genericServiceUser.group;
  };
  virtualisation.quadlet = {
    volumes = {
      warracker-db = { };
    };
    containers = {
      warracker-db.containerConfig = {
        image = "docker.io/library/postgres:15-alpine";
        environments = {
          POSTGRES_DB = "warracker";
          POSTGRES_USER = "warracker";
          POSTGRES_PASSWORD = "warracker";
        };
        volumes = [
          "${volumes.warracker-db.ref}:/var/lib/postgresql"
        ];
        labels = {
          "traefik.enable" = "false";
        };
        healthInterval = "600s";
        healthTimeout = "10s";
        healthRetries = 3;
        healthStartPeriod = "40s";
        healthCmd = "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB";
      };
      warracker = {
        unitConfig = {
          Requires = [
            containers.warracker-db.ref
          ];
          After = [
            containers.warracker-db.ref
          ];
        };
        containerConfig = {
          image = "ghcr.io/sassanix/warracker/main:latest";
          environments =
            let
              dbenv = containers.warracker-db.containerConfig.environments;
            in
            {
              DB_HOST = "warracker-db";
              DB_PORT = "5432";
              DB_NAME = dbenv.POSTGRES_DB;
              DB_USER = dbenv.POSTGRES_USER;
              DB_PASSWORD = dbenv.POSTGRES_PASSWORD;
              MAX_UPLOAD_MB = "32";
              WARRACKER_MEMORY_MODE = "optimized";
              OIDC_ONLY_MODE = "true";
              OIDC_PROVIDER_NAME = "oidc";
              OIDC_ENABLED = "true";
              OIDC_ISSUER_URL = "https://pocket-id.${mainaddr}";
              OIDC_ADMIN_GROUP = "warrantyadmin";
              FRONTEND_URL = "https://${url}/";
              APP_BASE_URL = "https://${url}/";
              PYTHONUNBUFFERED = "1";
            };
          environmentFiles = [
            config.age.secrets.warracker-env.path
          ];
          volumes = [
            "${sharesdir}/Warracker/:/data/uploads"
          ];
          labels = {
            "traefik.http.routers.warracker.rule" = "Host(`${url}`)";
            "traefik.http.services.warracker.loadbalancer.server.port" = "80";
            "traefik.http.routers.warracker.middlewares" = "tinyauth";
            "tinyauth.apps.warranty.oauth.groups" = "warranty";
          };
        };
      };
    };
  };
}
