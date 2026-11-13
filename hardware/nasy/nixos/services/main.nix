{
  pkgs,
  lib,
  config,
  genericServiceUser,
  myuser,
  ...
}:
{
  _module.args = rec {
    mainaddr = "whvdjsi.duckdns.org";
    configdir = "/storage/configs/";
    sharesdir = "/storage/Shares/";
    mkTraefikLabels =
      {
        subdomain,
        application ? subdomain,
        port ? 80,
        public ? false,
        oauth-groups ? null,
        vpn ? false,
        middlewares ? [ ],
        network ? if vpn then "podman" else null,
      }:
      let
        host = "${subdomain}.${mainaddr}";
        directMiddlewares = middlewares ++ lib.lists.optional (oauth-groups != null) "tinyauth";
        mkRouter =
          {
            name,
            rule,
            priority ? null,
            routerMiddlewares ? [ ],
          }:
          {
            "traefik.http.routers.${name}.rule" = rule;
            "traefik.http.routers.${name}.service" = application;
            "traefik.http.routers.${name}.entrypoints" = "http,https";
          }
          // lib.attrsets.optionalAttrs (priority != null) {
            "traefik.http.routers.${name}.priority" = toString priority;
          }
          // lib.attrsets.optionalAttrs (routerMiddlewares != [ ]) {
            "traefik.http.routers.${name}.middlewares" = lib.concatStringsSep "," routerMiddlewares;
          };
      in
      lib.attrsets.mergeAttrsList (
        [
          { "traefik.http.services.${application}.loadbalancer.server.port" = toString port; }
        ]
        ++ lib.lists.optional public (
          # Requests relayed by Newt arrive over loopback and already passed
          # Pangolin's identity-provider login; skip tinyauth for those only.
          mkRouter {
            name = "${application}-tunnel";
            rule = "Host(`${host}`) && ClientIP(`127.0.0.1/32`)";
            priority = 100;
            routerMiddlewares = middlewares;
          }
        )
        ++ [
          (mkRouter {
            name = application;
            rule = "Host(`${host}`)";
            priority = if public then 50 else null;
            routerMiddlewares = directMiddlewares;
          })
        ]
        ++ lib.lists.optional (oauth-groups != null) {
          "tinyauth.apps.${application}.oauth.groups" = oauth-groups;
        }
        ++ lib.lists.optional (network != null) { "traefik.docker.network" = network; }
      );
  };
  users.users."${myuser}".linger = true;
  networking.firewall.interfaces."podman+".allowedUDPPorts = [
    53
    5353
  ];
  systemd.services.podman-restart.wantedBy = lib.mkIf config.virtualisation.podman.enable [
    "default.target"
  ];
  virtualisation = {
    containers.registries.settings = {
      unqualified-search-registries = [
        "docker.io"
        "quay.io"
      ];
    };
    quadlet.enable = true;
    podman = {
      dockerSocket.enable = true;
      enable = true;
      autoPrune.enable = true;
      dockerCompat = true;
      defaultNetwork.settings = {
        dns_enabled = true;
      };
    };
    oci-containers.backend = "podman";
  };
  environment.systemPackages = with pkgs; [
    docker-compose
    podman-compose
    slirp4netns
    fuse-overlayfs
    dig
  ];
  system.activationScripts.ensurePodmanVolumes.text =
    let
      inherit (builtins)
        attrValues
        concatMap
        filter
        head
        concatStringsSep
        ;
      inherit (lib) hasPrefix pipe splitString;
    in
    pipe config.virtualisation.oci-containers.containers [
      attrValues
      (concatMap (c: c.volumes))
      (filter (v: hasPrefix "/storage" v))
      (map (v: head (splitString ":" v)))
      (map (p: ''
        if [ ! -e "${p}" ]; then
            mkdir -p "${p}" && chown ${toString genericServiceUser.uid} "${p}"
        fi
      ''))
      (concatStringsSep "\n")
    ];
}
