{
  lib,
  config,
  mainaddr,
  configdir,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers;
in
{
  services.grafana = {
    enable = true;
    openFirewall = false;
    dataDir = "${configdir}/grafana";
    settings = {
      security.secret_key = "SW2YcwTIb9zpOOhoPsMm";
      server = {
        http_addr = "127.0.0.1";
        domain = "grafana.${mainaddr}";
        rootUrl = "http://grafana.${mainaddr}";
        protocol = "http";
      };
      users = {
        allow_sign_up = false;
        auto_assign_org = true;
        auto_assign_org_role = "Editor";

      };
      auth = {
        disable_login_form = true;
        disable_signout_menu = true;
        oauth_skip_org_role_update_sync = true;
      };
      "auth.proxy" = {
        enabled = true;
        header_name = "Remote-User";
        headers = "Groups:Remote-Groups";
        header_property = "username";
        auto_sign_upp = true;
        ldap_sync_ttl = 60;
        role_attribute_strict = true;
        allow_assign_grafana_admin = true;
      };
    };

    provision.enable = true;
  };

  virtualisation.quadlet.containers.tinyauth.containerConfig.labels."tinyauth.apps.grafana.oauth.groups" =
    lib.mkIf (containers ? tinyauth) "admin";
  services.traefik.dynamicConfigOptions.http = {
    routers.grafana = {
      rule = "Host(`grafana.${mainaddr}`)";
      service = "grafana";
      entryPoints = [
        "http"
        "https"
      ];
      middlewares = [ "tinyauth@docker" ];
      tls = { };
    };
    services.grafana.loadBalancer.servers = [
      {
        url = "http://localhost:${toString config.services.grafana.settings.server.http_port}/";
      }
    ];
  };
}
