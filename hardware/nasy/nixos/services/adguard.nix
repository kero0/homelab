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
  my.services.adguardserver = {
    enable = true;
    bind_hosts = [ "10.5.0.123" ];
    openPorts = true;
    inherit httpPort;
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
