{
  config,
  lib,
  mainaddr,
  pkgs,
  sharesdir,
  ...
}:
let
  httpPort = 3167;
  subdomain = "presentations";
  tinyauth = config.virtualisation.quadlet.containers ? tinyauth;
in
{
  systemd.services.revealjs = {
    description = "Reveal.js Presentation Server";

    serviceConfig = {
      WorkingDirectory = "${sharesdir}/Revealjs";
      ExecStart = "${pkgs.python3}/bin/python -m http.server --bind 127.0.0.1 ${toString httpPort}";
      Restart = "always";
      DynamicUser = true;
    };

    wantedBy = [ "multi-user.target" ];
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
