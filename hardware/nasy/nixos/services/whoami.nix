{
  lib,
  config,
  pkgs,
  mainaddr,
  configdir,
  sharesdir,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers;
in
{
  virtualisation.quadlet = {
    containers.whoami.containerConfig = {
      image = "docker.io/traefik/whoami:latest";
      labels = {
        "traefik.http.services.whoami.loadbalancer.server.port" = "80";
        "traefik.http.routers.whoami.middlewares" = lib.mkIf (containers ? tinyauth) "tinyauth";
      };
    };
  };
}
