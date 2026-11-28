{
  config,
  lib,
  mainaddr,
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
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      libusb1
      openssl
    ];
  };

  systemd.services.esphome = {
    path = with pkgs; [
      bash
      cmake
      coreutils
      gnumake
      git
    ];
    environment = {
      inherit (config.environment.variables) NIX_LD NIX_LD_LIBRARY_PATH;
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
