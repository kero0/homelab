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
    nixos.url = "github:kero0/nixos";
    authentik-nix.url = "github:nix-community/authentik-nix";
    deploy-rs.url = "github:serokell/deploy-rs";
    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
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
      inherit (nixos.inputs) nixpkgs nixos-hardware lanzaboote;
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
                exclude = [ ".*/secrets.nix" ];
                age = true;
                defaultsecrets = false;
              }
              ++ [
                nixos-hardware.nixosModules.common-cpu-intel
                nixos-hardware.nixosModules.common-pc
                nixos-hardware.nixosModules.common-pc-ssd
                quadlet-nix.nixosModules.quadlet
                lanzaboote.nixosModules.lanzaboote

                inputs.authentik-nix.nixosModules.default
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
      };

      devShells =
        let
          inherit (builtins) mapAttrs;
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
              packages = [ pkgs.deploy-rs ];
              inputsFrom = [ value.default ];
            };
          }
        ) devShells;

      deploy.nodes.nasy = {
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

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
