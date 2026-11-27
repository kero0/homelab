{
  config,
  lib,
  pkgs,
  ...
}:
let
  s = import ../settings.nix;
  key = name: config.age.secrets.${name}.path;
  nordTable = 1000;
in
{
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  systemd = {
    network = {
      netdevs = {
        "30-wg0" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "wg0";
            MTUBytes = "1420";
          };
          wireguardConfig = {
            PrivateKeyFile = key "wg0";
            ListenPort = s.clients.port;
          };
          wireguardPeers = map (p: {
            PublicKey = p.publicKey;
            AllowedIPs = [ p.ip ];
          }) s.clients.peers;
        };

        "30-wg-home" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "wg-home";
            MTUBytes = "1420";
          };
          wireguardConfig = {
            PrivateKeyFile = key "wg-home";
            ListenPort = s.home.port;
          };
          wireguardPeers = [
            (
              {
                PublicKey = s.home.publicKey;
                AllowedIPs = s.home.routes;
                PersistentKeepalive = 25;
              }
              // lib.optionalAttrs (s.home.endpoint != null) { Endpoint = s.home.endpoint; }
            )
          ];
        };

        "30-nord" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "nord";
            MTUBytes = "1420";
          };
          wireguardConfig.PrivateKeyFile = key "nord";
          wireguardPeers = [
            {
              PublicKey = s.nord.publicKey;
              Endpoint = s.nord.endpoint;
              AllowedIPs = [ "0.0.0.0/0" ];
              PersistentKeepalive = 25;
            }
          ];
        };
      };
      networks = {
        "30-wg0" = {
          matchConfig.Name = "wg0";
          address = [ s.clients.address ];
          routes = [
            {
              Destination = "0.0.0.0/0";
              Type = "unreachable";
              Table = nordTable;
              Metric = 4096;
            }
          ];
          routingPolicyRules = [
            {
              From = s.clients.subnet;
              Table = "main";
              SuppressPrefixLength = 0;
              Priority = 100;
            }
            {
              From = s.clients.subnet;
              Table = nordTable;
              Priority = 200;
            }
          ];
        };

        "30-wg-home" = {
          matchConfig.Name = "wg-home";
          address = [ s.home.address ];
          routes = map (r: { Destination = r; }) s.home.routes;
        };

        "30-nord" = {
          matchConfig.Name = "nord";
          address = [ s.nord.address ];
          routes = [
            {
              Destination = "0.0.0.0/0";
              Table = nordTable;
            }
          ];
          # strict rpfilter drops nord's replies without this
          routingPolicyRules = [
            {
              From = s.nord.address;
              Table = nordTable;
              Priority = 200;
            }
          ];
        };
      };
    };

    # networkd doesn't seem to re-resolve endpoint hostnames (ddns)
    services.wireguard-endpoint-refresh = {
      description = "Re-resolve WireGuard peer endpoint hostnames";
      after = [
        "systemd-networkd.service"
        "network-online.target"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "systemd-networkd.service" ];
      path = [ pkgs.wireguard-tools ];
      serviceConfig.Type = "oneshot";
      script = lib.concatStringsSep "\n" (
        [ "rc=0" ]
        ++
          lib.optional (s.home.endpoint != null)
            "wg set wg-home peer ${lib.escapeShellArg s.home.publicKey} endpoint ${lib.escapeShellArg s.home.endpoint} || rc=1"
        ++ [
          "wg set nord peer ${lib.escapeShellArg s.nord.publicKey} endpoint ${lib.escapeShellArg s.nord.endpoint} || rc=1"
          "exit $rc"
        ]
      );
    };
    timers.wireguard-endpoint-refresh = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = "5min";
      };
    };
  };

  networking = {
    nftables.enable = true;
    firewall = {
      enable = true;
      checkReversePath = "strict";
      allowedUDPPorts = [ s.clients.port ] ++ lib.optional (s.home.endpoint == null) s.home.port;
    };

    nftables.tables.vpn = {
      family = "inet";
      content = ''
        chain forward {
          type filter hook forward priority filter; policy drop;
          ct state established,related accept
          iifname "wg0" oifname { "nord", "wg-home", "wg0" } accept
        }
        chain mangle-forward {
          type filter hook forward priority mangle;
          tcp flags syn tcp option maxseg size set rt mtu
        }
        chain postrouting {
          type nat hook postrouting priority srcnat;
          ip saddr ${s.clients.subnet} oifname { "nord", "wg-home" } masquerade
        }
        # sidestore: what localdevvpn/em_proxy do on the phone. a connection to
        # ${s.clients.loopback} goes back to the phone that made it, from ${s.clients.loopback},
        # so the phone reaches its own lockdownd while the vpn is up
        chain loopback {
          type nat hook prerouting priority dstnat;
          iifname "wg0" ip daddr ${s.clients.loopback} dnat ip to ip saddr
        }
        chain loopback-snat {
          type nat hook postrouting priority srcnat;
          oifname "wg0" ct original ip daddr ${s.clients.loopback} snat ip to ${s.clients.loopback}
        }
      '';
    };
  };
}
