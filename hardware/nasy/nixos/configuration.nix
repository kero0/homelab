{
  config,
  lib,
  genericServiceUser,
  pkgs,
  ...
}:
{
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  networking = {
    hostId = "676bfee2";
    networkmanager.enable = true;
    firewall.enable = true;
  };
  time.timeZone = "America/Detroit";
  i18n.defaultLocale = "en_US.UTF-8";

  security.sudo.wheelNeedsPassword = false;

  users = {
    groups.${genericServiceUser.group} = {
      inherit (genericServiceUser) gid;
    };
    users = {
      "${config.my.user.username}" = {
        extraGroups = [
          "audio"
          "dialout"
          "docker"
          "kvm"
          "tty"
          "video"
          "wheel"
          genericServiceUser.group
        ]
        ++ lib.lists.optional (config.users.groups ? docker) "docker"
        ++ lib.lists.optional (config.users.groups ? podman) "podman";
      };
      ${genericServiceUser.name} = {
        inherit (genericServiceUser) name;
        inherit (genericServiceUser) group;
        inherit (genericServiceUser) uid;
        isSystemUser = false;
        isNormalUser = true;
        linger = true;
        extraGroups =
          lib.lists.optional (config.users.groups ? docker) "docker"
          ++ lib.lists.optional (config.users.groups ? podman) "podman";

      };
    };
    mutableUsers = false;
  };

  services = {
    journald.extraConfig = "SystemMaxUse=100M";
    fwupd.enable = true;
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        X11Forwarding = true;
      };
      openFirewall = true;
    };
    xserver.xkb.layout = "us";
  };
  environment.systemPackages = with pkgs; [ vim ];
}
