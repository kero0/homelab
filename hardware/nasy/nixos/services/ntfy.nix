{
  mainaddr,
  ...
}:
let
  mainPort = "6111";
  metricsPort = "6112";
in
{
  services = {
    ntfy-sh = {
      enable = true;
      settings = {
        base-url = "https://ntfy.${mainaddr}";
        listen-http = "127.0.0.1:${mainPort}";
        upstream-base-url = "https://ntfy.sh";
        behind-proxy = true;

        auth-default-access = "deny-all";
        enable-login = true;
        require-login = true;

        enable-metrics = true;
        metrics-listen-http = "127.0.0.1:${metricsPort}";

        attachment-file-size-limit = "20M";
        attachment-total-size-limit = "1G";

        web-push-email-address = "kirolsb5@gmail.com";
      };
    };
    prometheus.scrapeConfigs = [
      {
        job_name = "ntfy";
        static_configs = [
          {
            targets = [ "localhost:${metricsPort}" ];
          }
        ];
      }
    ];
    traefik.dynamicConfigOptions.http = {
      routers.ntfy = {
        rule = "Host(`ntfy.${mainaddr}`)";
        service = "ntfy";
        entryPoints = [
          "http"
          "https"
        ];
        tls = { };
      };
      services.ntfy.loadBalancer.servers = [
        {
          url = "http://localhost:${mainPort}/";
        }
      ];
    };
  };

}
