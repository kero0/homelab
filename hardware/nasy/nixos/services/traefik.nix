{
  config,
  mainaddr,
  configdir,
  ...
}:
{
  networking.firewall.allowedTCPPorts = [
    80
    443
    8080
  ];
  users.users.traefik.extraGroups = [
    "services"
    config.virtualisation.oci-containers.backend
  ];
  systemd.services.traefik = {
    wants = [
      "${config.virtualisation.oci-containers.backend}.service"
    ];
    after = [
      "${config.virtualisation.oci-containers.backend}.service"
    ];
  };
  services.traefik = {
    enable = true;
    environmentFiles = [
      config.age.secrets.dns-pass.path
    ];
    dynamicConfigOptions = {
      http = {
        middlewares = {
          "homeassistant-addHost" = {
            headers = {
              # STSIncludeSubdomains = "true";
              # STSPreload = "true";
              # contentTypeNosniff = "true";
              # customResponseHeaders.X-Robots-Tag = "noindex,nofollow,nosnippet,noarchive,notranslate,noimageindex";
              # customresponseheaders.X-XSS-PROTECTION = "1";
              # forceSTSHeader = "true";
              # frameDeny = "true";
              customRequestHeaders.Host = "hass.lan";
            };
          };
        };
        routers = {
          # esphome = {
          #   rule = "Host(`esphome.${mainaddr}`)";
          #   middlewares = [ "homeassistant-addHost" ];
          #   service = "esphome";
          #   entryPoints = [
          #     "http"
          #     "https"
          #   ];
          #   tls = { };
          # };
          homeassistant = {
            rule = "Host(`homeassistant.${mainaddr}`)";
            middlewares = [ "homeassistant-addHost" ];
            service = "homeassistant";
            entryPoints = [
              "http"
              "https"
            ];
            tls = { };
          };
          # matter = {
          #   rule = "Host(`matter.${mainaddr}`)";
          #   middlewares = [ "homeassistant-addHost" ];
          #   service = "matter";
          #   entryPoints = [
          #     "http"
          #     "https"
          #   ];
          #   tls = { };
          # };
          traefik = {
            rule = "Host(`traefik.${mainaddr}`)";
            service = "api@internal";
            entryPoints = [
              "http"
              "https"
            ];
            tls = { };
          };
        };
        services = {
          esphome.loadBalancer.servers = [
            { url = "http://hass.lan:6052"; }
          ];
          homeassistant.loadBalancer.servers = [
            { url = "http://hass.lan:8123"; }
          ];
          matter.loadBalancer.servers = [
            { url = "http://hass.lan:5580"; }
          ];
          traefik.loadBalancer.servers = [
            { url = "http://hass.lan:8080"; }
          ];
        };
      };
    };

    staticConfigOptions = {
      global = {
        sendAnonymousUsage = false;
        checkNewVersion = false;
      };
      api = {
        dashboard = true;
        insecure = true;
      };
      log = {
        level = "DEBUG";
      };
      entryPoints = {
        http = {
          address = ":80";
          http = {
            redirections = {
              entryPoint = {
                to = "https";
                scheme = "https";
                permanent = true;
              };
            };
          };
          forwardedHeaders = {
            trustedIPs = [
              "10.0.0.0/8"
              "127.0.0.1/32"
              "172.16.0.0/12"
              "192.168.0.0/16"
              "fc00::/7"
            ];
          };
          proxyProtocol = {
            trustedIPs = [
              "10.0.0.0/8"
              "127.0.0.1/32"
              "172.16.0.0/12"
              "192.168.0.0/16"
              "fc00::/7"
            ];
          };
        };
        https = {
          address = ":443";
          http = {
            tls = {
              certResolver = "myresolver";
              domains = [
                {
                  main = mainaddr;
                  sans = [ "*.${mainaddr}" ];
                }
              ];
            };
          };
          forwardedHeaders = {
            trustedIPs = [
              "10.0.0.0/8"
              "172.16.0.0/12"
              "192.168.0.0/16"
              "fc00::/7"
            ];
            insecure = false;
          };
          proxyProtocol = {
            trustedIPs = [
              "10.0.0.0/8"
              "172.16.0.0/12"
              "192.168.0.0/16"
              "fc00::/7"
            ];
            insecure = false;
          };
        };
      };
      providers = {
        docker = {
          endpoint = "unix:///run/podman/podman.sock";
          exposedByDefault = true;
          defaultRule = "Host(`{{ .ContainerName }}.${mainaddr}`)";
        };
      };
      certificatesResolvers = {
        myresolver = {
          acme = {
            email = "kirolsb5@gmail.com";
            storage = "${configdir}/traefik/myresolver/acme.json";
            dnsChallenge = {
              provider = "duckdns";
              propagation.delayBeforeChecks = 120;
            };
          };
        };
      };
    };
  };
}
