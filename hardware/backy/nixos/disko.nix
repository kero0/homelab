{
  services = {
    zfs.autoScrub.enable = true;
    zfs.trim.enable = true;
  };
  boot = {
    kernelParams = [ "zfs_force=1" ];
    supportedFilesystems = [ "zfs" ];

    zfs = {
      forceImportRoot = true;
      forceImportAll = true;
      devNodes = "/dev/disk/by-partlabel";
      # extraPools = [ "storage" ];
    };
  };
  disko.devices = {
    disk = {
      rootfs = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              name = "boot";
              size = "1M";
              type = "EF02";
            };
            esp = {
              name = "ESP";
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };

            encryptedSwap = {
              size = "512M";
              content = {
                type = "swap";
                randomEncryption = true;
                priority = 100;
              };
            };
            plainSwap = {
              size = "4G";
              content = {
                type = "swap";
                discardPolicy = "both";
                resumeDevice = true;
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
      storagefs = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "storage";
              };
            };
          };
        };
      };
    };
    zpool = {
      storage = {
        type = "zpool";
        options.cachefile = "none";
        rootFsOptions = {
          mountpoint = "none";
          compression = "zstd";
          acltype = "posixacl";
          xattr = "sa";
          atime = "off";
        };

        datasets = {
          backups = {
            type = "zfs_fs";
            options.mountpoint = "/storage/backups";
          };
          nix_fs = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/nix";
          };
        };
      };
    };
  };
}
