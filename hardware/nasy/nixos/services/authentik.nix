{
  lib,
  config,
  mainaddr,
  configdir,
  sharesdir,
  ...
}:
{
  config = lib.mkIf false {
    services.authentik = {
      enable = true;
      nginx.enable = false;
      environmentFile = config.age.secrets.authentik-env.path;
      settings = {
        email = {
          host = "smtp.gmail.com";
          port = 587;
          username = "kirolsb5@gmail.com";
          use_tls = true;
          use_ssl = false;
          from = "kirolsb5@gmail.com";
        };
        disable_startup_analytics = true;
        avatars = "initials";
      };
    };
    services.traefik = {
      dynamicConfigOptions.http = {
        middlewares.authentik = {
          forwardAuth = {
            tls.insecureSkipVerify = true;
            address = "https://localhost:9443/outpost.goauthentik.io/auth/traefik";
            trustForwardHeader = true;
            authResponseHeaders = [
              "X-authentik-username"
              "X-authentik-groups"
              "X-authentik-entitlements"
              "X-authentik-email"
              "X-authentik-name"
              "X-authentik-uid"
              "X-authentik-jwt"
              "X-authentik-meta-jwks"
              "X-authentik-meta-outpost"
              "X-authentik-meta-provider"
              "X-authentik-meta-app"
              "X-authentik-meta-version"
            ];
          };
        };
        routers = {
          default-router-auth = {
            rule = "PathPrefix(`/outpost.goauthentik.io/`)";
            priority = 15;
            service = "authentik";
          };
          authentik-dashboard = {
            # rule = "Host(`sso.${mainaddr}`)";
            rule = "Host(`authentik.${mainaddr}`) || HostRegexp(`{subdomain:[a-z0-9]+}.${mainaddr}`) && PathPrefix(`/outpost.goauthentik.io/`)";

            service = "authentik-dashboard";
            entryPoints = [
              "web"
              "websecure"
            ];
            tls = { };
          };
        };
        serversTransports.authentik.insecureSkipVerify = true;
        services = {
          authentik.loadBalancer = {
            serversTransport = "authentik";
            servers = [
              {
                url = "http://localhost:9000";
              }
            ];
          };
        };
      };
    };
  };
}
