{
  config,
  lib,
  configdir,
  pkgs,
  ...
}:
{
  services.loki = {
    enable = true;
    dataDir = "${configdir}/loki";
    configuration = {
      analytics.reporting_enabled = false;
      auth_enabled = false;

      server = {
        http_listen_port = 3100;
        grpc_listen_port = 9123;
      };
      ingester = {
        lifecycler = {
          address = "127.0.0.1";
          ring = {
            kvstore = {
              store = "inmemory";
            };
            replication_factor = 1;
          };
        };
        chunk_idle_period = "1h";
        max_chunk_age = "1h";
        chunk_target_size = 999999;
        chunk_retain_period = "30s";
      };
      common = {
        ring = {
          instance_addr = "127.0.0.1";
          kvstore.store = "inmemory";
        };
        replication_factor = 1;
        path_prefix = config.services.loki.dataDir;
      };
      schema_config.configs = [
        {
          from = "2026-03-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];
      storage_config = {
        tsdb_shipper = {
          active_index_directory = "${config.services.loki.dataDir}/tsdb-index";
          cache_location = "${config.services.loki.dataDir}/tsdb-cache";
          cache_ttl = "24h";
        };
        filesystem.directory = "${config.services.loki.dataDir}/chunks";
      };
      limits_config = {
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
      };

      table_manager = {
        retention_deletes_enabled = false;
        retention_period = "0s";
      };
      compactor = {
        working_directory = config.services.loki.dataDir;
        compactor_ring = {
          kvstore = {
            store = "inmemory";
          };
        };
      };
    };
  };
  services.grafana.provision = {
    datasources.settings.datasources = [
      {
        name = "Loki";
        type = "loki";
        access = "proxy";
        url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
      }
    ];
    dashboards.settings.providers = [
      {
        name = "Loki";
        options.path =
          let
            src =
              let
                inherit (builtins)
                  attrNames
                  attrValues
                  fetchurl
                  readFile
                  replaceStrings
                  ;
                replacements = {
                  "\${DS_LOKI}" = "Loki";
                };
              in
              lib.pipe
                {
                  url = "https://grafana.com/api/dashboards/13639/revisions/2/download";
                  sha256 = "101lai075g45sspbnik2drdqinzmgv1yfq6888s520q8ia959m6r";
                }
                [
                  fetchurl
                  readFile
                  (replaceStrings (attrNames replacements) (attrValues replacements))
                  (pkgs.writeText "loki.json")
                ];
          in
          pkgs.runCommand "Loki-Dashboard" { } ''
            mkdir $out;
            cp ${src} $out/loki.json
          '';
        updateIntervalSeconds = 60 * 60 * 24 * 365;
        disableDeletion = true;
      }
    ];
  };
}
