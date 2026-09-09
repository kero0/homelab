{
  lib,
  config,
  mkTraefikLabels,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers;
in
{
  virtualisation.quadlet = {
    containers.whoami.containerConfig = {
      image = "docker.io/traefik/whoami:latest";
      labels =
        mkTraefikLabels {
          subdomain = "whoami";
          public = true;
        }
        // {
          "traefik.http.services.whoami.loadbalancer.server.port" = "80";
          "traefik.http.routers.whoami.middlewares" = lib.mkIf (containers ? tinyauth) "tinyauth";
        };
    };
  };
}
