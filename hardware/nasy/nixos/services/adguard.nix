{
  config,
  lib,
  mainaddr,
  ...
}:
let
  httpPort = 3184;
  subdomain = "adguard";
  tinyauth = config.virtualisation.quadlet.containers ? tinyauth;
in
{
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    host = "127.0.0.1";
    port = httpPort;
    settings = {
      dns = {
        bind_hosts = [ "10.5.10.22" ];
        port = 53;
        upstream_dns = [
          "https://dns.quad9.net/dns-query"
          "https://dns.cloudflare.com/dns-query"
        ];
        bootstrap_dns = [
          "9.9.9.9"
          "1.1.1.1"
        ];
      };
      trusted_proxies = [
        "127.0.0.1"
        "::1"
      ];
      users = [ ];
      filters_update_interval = 24;
      querylog.interval = "${toString (7 * 24)}h";
      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
        parental_enabled = false;
        safe_search.enabled = false;
      };
      filters = [
        {
          id = 1;
          enabled = true;
          name = "AdGuard DNS filter";
          url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
        }
        {
          id = 2;
          enabled = true;
          name = "OISD Basic";
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt";
        }
        {
          id = 3;
          enabled = true;
          name = "AdGuard Mobile Ads";
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_4.txt";
        }
      ];
    };
  };
  virtualisation.quadlet.containers.tinyauth.containerConfig.labels."tinyauth.apps.${subdomain}.oauth.groups" =
    lib.mkIf tinyauth "admin,main";
  services.traefik.dynamicConfigOptions.http = {
    routers.${subdomain} = {
      rule = "Host(`${subdomain}.${mainaddr}`)";
      service = "${subdomain}";
      entryPoints = [
        "http"
        "https"
      ];
      middlewares = lib.lists.optional tinyauth "tinyauth@docker";
      tls = { };
    };
    services.${subdomain}.loadBalancer.servers = [
      {
        url = "http://localhost:${toString httpPort}/";
      }
    ];
  };
}
