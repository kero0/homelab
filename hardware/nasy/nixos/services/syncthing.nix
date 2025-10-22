{
  lib,
  config,
  mainaddr,
  configdir,
  sharesdir,
  ...
}:
let
  port = toString 8234;
in
{
  services.traefik = {
    enable = true;
    dynamicConfigOptions.http = {
      routers.syncthing = {
        rule = "Host(`syncthing.${mainaddr}`)";
        service = "syncthing";
        entryPoints = [
          "web"
          "websecure"
        ];
        tls = { };
      };
      services.syncthing.loadBalancer.servers = [
        {
          url = "http://localhost:${port}";
        }
      ];
    };
  };
}
