{
  lib,
  config,
  mainaddr,
  configdir,
  sharesdir,
  ...
}:
{
  services.traefik.dynamicConfigOptions.http = {
    routers.syncthing = {
      rule = "Host(`syncthing.${mainaddr}`)";
      service = "syncthing";
      entryPoints = [
        "http"
        "https"
      ];
      tls = { };
    };
    services.syncthing.loadBalancer.servers = [
      {
        url = "http://localhost:8384/";
      }
    ];
  };
}
