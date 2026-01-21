{
  config,
  lib,
  pkgs,
  stable,
  genericServiceUser,
  ...
}:
let
  sharepath = "/storage/Shares";
in
{
  networking.firewall.allowPing = true;
  users.users = {
    tootsie = {
      group = "samba";
      isNormalUser = true;
      extraGroups = [ genericServiceUser.group ];
    };
    kirolsbakheat = {
      group = "samba";
      isNormalUser = true;
      extraGroups = [
        genericServiceUser.group
        "users"
      ];
    };
  };
  users.groups.samba = { };
  services = {
    samba-wsdd = {
      enable = true;
      openFirewall = true;
    };
    samba = {
      enable = true;
      package = pkgs.samba;
      openFirewall = true;
      nmbd.enable = true;
      nsswins = true;
      smbd.enable = true;
      winbindd.enable = true;
      usershares.enable = true;
      settings = {
        global = {
          workgroup = "WORKGROUP";
          "server string" = config.networking.hostName;
          "netbios name" = config.networking.hostName;
          security = "user";
          "hosts allow" = "192.168.1.1/8 10.0.0.0/8 127.0.0.1 localhost ::1";
          "hosts deny" = "0.0.0.0/0";
          "guest account" = "nobody";
          "map to guest" = "Bad User";
          # "load printers" = "yes";

          # for time machine
          "vfs objects" = "fruit streams_xattr";
          "fruit:metadata" = "stream";
          "fruit:model" = "MacSamba";
          "fruit:posix_rename" = "yes";
          "fruit:veto_appledouble" = "no";
          "fruit:nfs_aces" = "no";
          "fruit:wipe_intentionally_left_blank_rfork" = "yes";
          "fruit:delete_empty_adfiles" = "yes";
          # "fruit:aapl" = "yes";
          # "fruit:copyfile" = "no";
          "min protocol" = "SMB2";
          "fruit:zero_file_id" = "yes";

          "ea support" = "yes";

          "allow insecure wide links" = "yes";
          "follow symlinks" = "yes";
          "wide links" = "yes";
          "unix extensions" = "yes";
          "inherit permissions" = "yes";
        };
        Downloads = {
          path = "${sharepath}/Downloads";
          "read only" = "yes";
          browseable = "yes";
          "guest ok" = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
          "fruit:veto_appledouble" = "yes";
          "force user" = "kirolsb";
          "force group" = "users";
        };
        Storage = {
          "path" = "${sharepath}/All";
          browseable = "yes";
          "read only" = "no";
          writeable = "yes";
          "guest ok" = "no";
          "valid users" = "@users";
          "create mask" = "0755";
          "directory mask" = "0755";
          "fruit:veto_appledouble" = "yes";
          "force user" = "kirolsb";
          "force group" = "users";
        };
        Games = {
          "path" = "${sharepath}/Games";
          browseable = "yes";
          "guest ok" = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
          "fruit:veto_appledouble" = "yes";
        };
        Timemachines = {
          "path" = "${sharepath}/Timemachines";
          "valid users" = "kirolsbakheat";
          public = "no";
          writeable = "yes";

          "vfs objects" = "fruit streams_xattr";
          "fruit:time machine" = "yes";
          "fruit:time machine max size" = "500G";
          "comment" = "Time Machine Backup";
          "available" = "yes";
          "browseable" = "yes";
          "guest ok" = "no";
        };
        # printers = {
        #   comment = "All Printers";
        #   path = "/var/spool/samba";
        #   public = "yes";
        #   browseable = "yes";
        #   # to allow user 'guest account' to print.
        #   "guest ok" = "yes";
        #   writable = "no";
        #   printable = "yes";
        #   "create mode" = 700;
        # };
      };
    };
  };
  systemd.tmpfiles.rules = [ "d /var/spool/samba 1777 root root -" ];
}
