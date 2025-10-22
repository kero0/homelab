{
  lib,
  config,
  pkgs,
  mainaddr,
  configdir,
  sharesdir,
  genericServiceUser,
  ...
}:
{
  virtualisation.oci-containers.containers.dockge = rec {
    image = "docker.io/louislam/dockge:1";
    autoStart = true;
    privileged = true;
    volumes = [
      "/run/podman/podman.sock:/var/run/docker.sock"
      "${configdir}/dockge/data:/app/data"
      "${configdir}/dockge/stacks:${configdir}/dockge/stacks"
    ];
    environment = {
      DOCKGE_STACKS_DIR = "${configdir}/dockge/stacks";
      DOCKGE_ENABLE_CONSOLE = "true";
      ADDRESS = mainaddr;
      STORAGE = sharesdir;
      CONFIG = configdir;
      UID = toString genericServiceUser.uid;
      GID = toString genericServiceUser.gid;
      TZ = config.time.timeZone;
    };
    labels = {
      "traefik.http.services.dockge.loadbalancer.server.port" = toString 5001;
    };
    log-driver = "journald";
    dependsOn = [ "vpn" ];
    extraOptions = [
      "--network=container:vpn"
    ];
  };
  systemd.services = {
    podman-dockge = {
      after = [
        "traefik.service"
      ];
    };
  };
}
