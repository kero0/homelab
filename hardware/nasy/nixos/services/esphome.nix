{
  config,
  lib,
  mainaddr,
  leaf-inputs,
  pkgs,
  ...
}:
let
  httpPort = 3367;
  subdomain = "esphome";
  tinyauth = config.virtualisation.quadlet.containers ? tinyauth;
in
{
  services.esphome = {
    enable = true;
    port = httpPort;
    address = "127.0.0.1";
    # package = (import leaf-inputs.nixpkgs-esphome { inherit (pkgs.hostPlatform) system; }).esphome;
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
