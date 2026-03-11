{
  config,
  pkgs,
  ...
}:
{
  services.prometheus = {
    enable = true;
    globalConfig.scrape_interval = "10s";
    scrapeConfigs = [
      {
        job_name = config.networking.hostName;
        static_configs = [
          {
            targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
          }
        ];
      }
    ];
    exporters.node = {
      enable = true;
      enabledCollectors = [ "systemd" ];
    };
  };
  services.grafana.provision = {
    datasources.settings.datasources = [
      {
        name = "Prometheus";
        type = "prometheus";
        url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
        isDefault = true;
        editable = false;
      }
    ];
    dashboards.settings.providers = [
      rec {
        name = "Prometheus";
        options.path =
          let
            src = pkgs.fetchFromGitHub {
              owner = "rfmoz";
              repo = "grafana-dashboards";
              rev = "76b2125f29757fc4886b8f25c6fa7ce96878fc4c";
              hash = "sha256-xRR2VQ/XkqSfhcON+idYgNQIZ5Sn1pSfYtqSdHKD4Bs=";
            };

          in
          pkgs.runCommand "Prometheus-Dashboard" { } ''
            mkdir $out;
            cp ${src}/prometheus/node-exporter-full.json $out/prometheus.json
          '';
        updateIntervalSeconds = 60 * 60 * 24 * 365;
        disableDeletion = true;
      }
    ];
  };
}
