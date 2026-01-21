{
  config,
  lib,
  pkgs,
  configdir,
  myuser,
  ...
}:
{
  age.secrets.vpn-pass = {
    mode = "444";
  };
  virtualisation.quadlet.containers.vpn = {
    autoStart = true;
    serviceConfig = {
      Restart = "always";
    };
    containerConfig = {
      image = "docker.io/qmcgaw/gluetun:latest";

      publishPorts = [
        "6881:6881/tcp"
        "6881:6881/udp"
      ];

      volumes = [
        "${configdir}/gluetun:/gluetun:rw"
      ];

      environments = {
        "PGID" = "${toString config.users.groups.services.gid}";
        "PUID" = "${toString config.users.users.serviceuser.uid}";
        "TZ" = config.time.timeZone;
        "VPN_SERVICE_PROVIDER" = "nordvpn";
        "VPN_TYPE" = "wireguard";
      };
      environmentFiles = [
        config.age.secrets.vpn-pass.path
      ];

      labels = {
        "traefik.enable" = "false";
      };

      addCapabilities = [
        "NET_ADMIN"
      ];

      devices = [
        "/dev/net/tun:/dev/net/tun:rwm"
      ];

      addHosts = [
        "host.docker.internal:host-gateway"
      ];
      logDriver = "journald";
    };
  };
}
