{
  pkgs,
  lib,
  config,
  genericServiceUser,
  ...
}:
{
  _module.args = {
    mainaddr = "whvdjsi.duckdns.org";
    configdir = "/storage/configs/";
    sharesdir = "/storage/Shares/";
  };
  networking.firewall.interfaces."podman+".allowedUDPPorts = [
    53
    5353
  ];
  virtualisation = {
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
