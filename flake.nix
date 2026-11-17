{
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://kero0.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "kero0.cachix.org-1:uzu0+ZP6R1U1izim/swa3bfyEiS0TElA8hLrGXQGAbA="
    ];
  };
  inputs = {
    nixos = {
      url = "github:kero0/nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
    calendar-display = {
      url = "github:kero0/calendar-display";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    ics-merger = {
      url = "github:kero0/ics-merger";
      flake = false;
    };
  };
  outputs =
    inputs@{
      self,
      nixos,
      deploy-rs,
      quadlet-nix,
      ...
    }:
    let
      inherit (nixos.inputs)
        agenix
        disko
        lanzaboote
        nixpkgs
        nixos-hardware
        ;
      inherit (nixos) mmodules umport;
    in
    {
      inherit (nixos) formatter;
      nixosConfigurations = {
        nasy =
          let
            myuser = "kirolsb";
            system = "x86_64-linux";
            hostname = "nasy";
          in
          nixpkgs.lib.nixosSystem {
            modules =
              mmodules {
                inherit hostname myuser system;
                # exclude = [ ".*/secrets.nix" ];
                age = false;
              }
              ++ [
                # nixos-hardware.nixosModules.common-cpu-intel
                nixos-hardware.nixosModules.common-pc
                nixos-hardware.nixosModules.common-pc-ssd
                quadlet-nix.nixosModules.quadlet
                lanzaboote.nixosModules.lanzaboote

                agenix.nixosModules.default

                {
                  _module.args = {
                    leaf-inputs = inputs;
                  };
                }

                {
                  home-manager.users.${myuser}.imports = umport {
                    ipath = ./hardware/nasy/home;
                  };
                }
              ]
              ++ umport {
                ipath = ./hardware/nasy/nixos;
                exclude = [ ".*/secrets.nix" ];
              };
          };
        backy =
          let
            myuser = "kirolsb";
            system = "x86_64-linux";
            hostname = "backy";
          in
          nixpkgs.lib.nixosSystem {
            modules =
              mmodules {
                inherit hostname myuser system;
                # exclude = [ ".*/secrets.nix" ];
                age = false;
              }
              ++ [
                disko.nixosModules.disko
                {
                  networking.hostId = "c2a42322";
                  disko.devices.disk = {
                    storagefs.device = "/dev/xvdb";
                    rootfs.device = "/dev/xvda";
                  };
                }
                {
                  home-manager.users.${myuser}.imports = umport {
                    ipath = ./hardware/nasy/home;
                  };
                }
              ]
              ++ umport {
                ipath = ./hardware/backy/nixos;
                exclude = [ ".*/secrets.nix" ];
              };
          };
        vpny =
          let
            myuser = "kirolsb";
            system = "aarch64-linux";
            hostname = "vpny";
          in
          nixpkgs.lib.nixosSystem {
            modules =
              mmodules {
                inherit hostname myuser system;
                age = false;
              }
              ++ [
                agenix.nixosModules.default
                {
                  home-manager.users.${myuser}.imports = umport {
                    ipath = ./hardware/vpny/home;
                  };
                }
              ]
              ++ umport {
                ipath = ./hardware/vpny/nixos;
                exclude = [ ".*/secrets.nix" ];
              };
          };
      };
      vms = nixpkgs.lib.attrsets.concatMapAttrs (host: config: {
        ${host} = config.pkgs.writeShellScriptBin "${host}" ''
          [ -z "$QEMU_NET_OPTS" ] && export QEMU_NET_OPTS="hostfwd=tcp::2221-:22"
          exec ${config.config.system.build.vmWithBootLoader}/bin/run-${host}-vm "$@"
        '';
      }) self.nixosConfigurations;

      devShells =
        let
          inherit (nixos) devShells;
          inherit (nixpkgs.lib) mapAttrs' nameValuePair;
        in
        mapAttrs' (
          name: value:
          let
            pkgs = import nixpkgs { system = name; };
          in
          nameValuePair name {
            default = pkgs.mkShell {
              packages = [
                pkgs.deploy-rs
                pkgs.oci-cli
                pkgs.opentofu
              ];
              inputsFrom = [ value.default ];
            };
          }
        ) devShells;

      deploy.nodes = {
        nasy = {
          hostname = "nasy";
          profiles.system = {
            sshUser = "kirolsb";
            sshOpts = [
              "-p"
              "9639"
            ];
            remoteBuild = true;
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nasy;
          };
        };
        backy = {
          hostname = "backy";
          profiles.system = {
            sshUser = "root";
            sshOpts = [
              "-p"
              "9639"
            ];
            remoteBuild = false;
            localBuild = true;
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.backy;
          };
        };
        vpny = {
          hostname = "163.192.192.83";
          profiles.system = {
            sshUser = "root";
            sshOpts = [
              "-p"
              "9639"
            ];
            remoteBuild = true;
            user = "root";
            path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.vpny;
          };
        };
      };

      checks = builtins.mapAttrs (
        system: deployLib:
        deployLib.deployChecks (
          self.deploy
          // {
            nodes = nixpkgs.lib.filterAttrs (
              name: _: self.nixosConfigurations.${name}.pkgs.stdenv.hostPlatform.system == system
            ) self.deploy.nodes;
          }
        )
      ) deploy-rs.lib;
    };
}
