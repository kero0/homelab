{
  config,
  lib,
  pkgs,
  configdir,
  ...
}:
{
  virtualisation.oci-containers.containers.vpn = {
    image = "docker.io/qmcgaw/gluetun:latest";
    environment = {
      "PGID" = "${toString config.users.groups.services.gid}";
      "PUID" = "${toString config.users.users.serviceuser.uid}";
      "TZ" = config.time.timeZone;
      "VPN_SERVICE_PROVIDER" = "nordvpn";
      "VPN_TYPE" = "wireguard";
    };
    environmentFiles = [
      config.age.secrets.vpn-pass.path
    ];
    volumes = [
      "${configdir}/gluetun:/gluetun:rw"
    ];
    ports = [
      "6881:6881/tcp"
      "6881:6881/udp"
    ];
    labels = {
      "traefik.enable" = "false";
    };
    log-driver = "journald";
    capabilities = {
      NET_ADMIN = true;
    };
    extraOptions = [
      "--add-host=host.docker.internal:host-gateway"
      "--cap-add=NET_ADMIN"
      "--device=/dev/net/tun:/dev/net/tun:rwm"
    ];
  };
}
