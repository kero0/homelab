{
  lib,
  config,
  mainaddr,
  sharesdir,
  ...
}:
let
  inherit (config.virtualisation.quadlet)
    containers
    pods
    networks
    volumes
    ;
  immichVersion = "release";
  usenvidia = true;
  nvString = lib.optionalString usenvidia;
  mkContainer = lib.recursiveUpdate {
    containerConfig = {
      pod = pods.immich.ref;
      environments = {
        TZ = config.time.timeZone;
        DB_USERNAME = "postgres";
        DB_DATABASE_NAME = "immich";
        DB_PASSWORD = "postgres";
      };
      autoUpdate = "registry";
      logDriver = "journald";
    };
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "30s";
    };
  };
  mkContainer2 = lib.recursiveUpdate {
    containerConfig = {
      pod = pods.immich-test.ref;
      environments = {
        TZ = config.time.timeZone;
        DB_USERNAME = "postgres";
        DB_DATABASE_NAME = "immich-test";
        DB_PASSWORD = "postgres";
      };
      autoUpdate = "registry";
      logDriver = "journald";
    };
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "30s";
    };
  };
in
{
  my.backup-shares = [ "Immich" ];
  age = {
    secrets.immich-config = {
      owner = config.users.users.serviceuser.name;
      group = config.users.groups.services.name;
    };
    secrets.immich-test-config = {
      owner = config.users.users.serviceuser.name;
      group = config.users.groups.services.name;
    };
  };
  virtualisation.quadlet = {
    networks.immich = { };
    networks.immich-test = { };
    pods.immich = {
      podConfig = {
        networks = [ networks.immich.ref ];
        podmanArgs = [ "--cpus=2" ];
      };
    };
    pods.immich-test = {
      podConfig = {
        networks = [ networks.immich-test.ref ];
        podmanArgs = [ "--cpus=2" ];
      };
    };
    volumes = {
      immich-postgres.volumeConfig = {
        user = "postgres";
        group = "postgres";
      };
      immich-machine-learning-cache.volumeConfig = {
        user = toString config.users.users.serviceuser.uid;
        group = toString config.users.groups.services.gid;
      };
      immich-test-postgres.volumeConfig = {
        user = "postgres";
        group = "postgres";
      };
      immich-test-machine-learning-cache.volumeConfig = {
        user = toString config.users.users.serviceuser.uid;
        group = toString config.users.groups.services.gid;
      };
    };
    containers = {
      immich-server = mkContainer {
        unitConfig = {
          Requires = "immich-redis.service immich-postgres.service";
        };
        containerConfig = {
          image = "ghcr.io/immich-app/immich-server:${immichVersion}";
          environments = {
            REDIS_HOSTNAME = "immich-redis";
            DB_HOSTNAME = "immich-postgres";
            IMMICH_CONFIG_FILE = "/config.yaml";
          };
          volumes = [
            "${sharesdir}/Immich:/usr/src/app/upload:rw"
            "${config.age.secrets.immich-config.path}:/config.yaml:ro"
            "/etc/localtime:/etc/localtime:ro"
          ];
          healthCmd = "curl -L 'localhost:2283/api/server/ping' -H 'Accept: application/json'";
          labels = {
            "traefik.docker.network" = "vpn";
            "traefik.http.routers.immich-server.rule" = "Host(`images.${mainaddr}`)";
            "traefik.http.services.immich-server.loadbalancer.server.port" = "2283";
          };
          logDriver = "journald";
          devices = [
            "/dev/dri:/dev/dri:rwm"
            "nvidia.com/gpu=all"
          ];
          user = toString config.users.users.serviceuser.uid;
          group = toString config.users.groups.services.gid;
        };
      };

      immich-machine-learning = mkContainer {
        containerConfig = {
          image = "ghcr.io/immich-app/immich-machine-learning:${immichVersion}${nvString "-cuda"}";
          volumes = [
            "${volumes.immich-machine-learning-cache.ref}:/cache:rw"
          ];
        };
      };

      immich-redis = mkContainer {
        containerConfig = {
          image = "docker.io/valkey/valkey:9@sha256:3b55fbaa0cd93cf0d9d961f405e4dfcc70efe325e2d84da207a0a8e6d8fde4f9";
          healthCmd = "redis-cli ping || exit 1";
        };
      };

      immich-postgres = mkContainer {
        containerConfig = {
          image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
          environments =
            let
              env = containers.immich-server.containerConfig.environments;
            in
            {
              POSTGRES_USERNAME = env.DB_USERNAME;
              POSTGRES_PASSWORD = env.DB_PASSWORD;
              POSTGRES_DB = env.DB_DATABASE_NAME;
              POSTGRES_INITDB_ARGS = "'--data-checksums'";
            };
          volumes = [
            "${volumes.immich-postgres.ref}:/var/lib/postgresql/data"
          ];
          healthCmd = "pg_isready -h localhost -p 5432 || exit 1";
          shmSize = "128mb";
          user = "postgres";
          group = "postgres";
        };
      };

      ## immich-test for testing
      immich-test-server = mkContainer2 {
        unitConfig = {
          Requires = "immich-redis.service immich-postgres.service";
        };
        containerConfig = {
          image = "ghcr.io/immich-app/immich-server:${immichVersion}";
          environments = {
            REDIS_HOSTNAME = "immich-test-redis";
            DB_HOSTNAME = "immich-test-postgres";
            IMMICH_CONFIG_FILE = "/config.yaml";
            IMMICH_ALLOW_SETUP = "true";
          };
          volumes = [
            "${sharesdir}/immich:/usr/src/app/upload:rw"
            "${config.age.secrets.immich-test-config.path}:/config.yaml:ro"
            "/etc/localtime:/etc/localtime:ro"
          ];
          healthCmd = "curl -L 'localhost:2283/api/server/ping' -H 'Accept: application/json'";
          labels = {
            "traefik.docker.network" = "vpn";
            "traefik.http.routers.immich-test-server.rule" = "Host(`immich.${mainaddr}`)";
            "traefik.http.services.immich-test-server.loadbalancer.server.port" = "2283";
          };
          logDriver = "journald";
          devices = [
            "/dev/dri:/dev/dri:rwm"
            "nvidia.com/gpu=all"
          ];
          user = toString config.users.users.serviceuser.uid;
          group = toString config.users.groups.services.gid;
        };
      };

      immich-test-machine-learning = mkContainer2 {
        containerConfig = {
          image = "ghcr.io/immich-app/immich-machine-learning:${immichVersion}${nvString "-cuda"}";
          volumes = [
            "${volumes.immich-test-machine-learning-cache.ref}:/cache:rw"
          ];
        };
      };

      immich-test-redis = mkContainer2 {
        containerConfig = {
          image = "docker.io/valkey/valkey:9@sha256:3b55fbaa0cd93cf0d9d961f405e4dfcc70efe325e2d84da207a0a8e6d8fde4f9";
          healthCmd = "redis-cli ping || exit 1";
        };
      };

      immich-test-postgres = mkContainer2 {
        containerConfig = {
          image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
          environments =
            let
              env = containers.immich-test-server.containerConfig.environments;
            in
            {
              POSTGRES_USERNAME = env.DB_USERNAME;
              POSTGRES_PASSWORD = env.DB_PASSWORD;
              POSTGRES_DB = env.DB_DATABASE_NAME;
              POSTGRES_INITDB_ARGS = "'--data-checksums'";
            };
          volumes = [
            "${volumes.immich-test-postgres.ref}:/var/lib/postgresql/data"
          ];
          healthCmd = "pg_isready -h localhost -p 5432 || exit 1";
          shmSize = "128mb";
          user = "postgres";
          group = "postgres";
        };
      };
    };
  };
}
