{
  config,
  mainaddr,
  lib,
  ...
}:
let
  subdomain = "ai";
in
{
  services.open-webui = {
    enable = true;
    port = 43124;
    environment = {
      OLLAMA_API_BASE_URL = "http://127.0.0.1:${toString config.services.ollama.port}";
      WEBUI_URL = "https://${subdomain}.${mainaddr}/";
      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";

      ENABLE_COMMUNITY_SHARING = "False";
      ENABLE_ADMIN_EXPORT = "False";

      ENABLE_OLLAMA_API = "True";
      ENABLE_OAUTH_SIGNUP = "True";
      ENABLE_PERSISTENT_CONFIG = "False";
      ENABLE_OAUTH_PERSISTENT_CONFIG = "False";
      WEBUI_AUTH = "True";
      ENABLE_SIGNUP = "True";
      DEFAULT_USER_ROLE = "user";
      WEBUI_AUTH_TRUSTED_EMAIL_HEADER = "Remote-Email";
      WEBUI_AUTH_TRUSTED_NAME_HEADER = "Remote-User";
      WEBUI_AUTH_TRUSTED_GROUPS_HEADER = "Remote-Groups";
      WEBUI_SESSION_COOKIE_SECURE = "True";
      WEBUI_AUTH_COOKIE_SECURE = "True";
      OAUTH_ADMIN_ROLES = "admin";
      ENABLE_OAUTH_GROUP_MANAGEMENT = "true";
      ENABLE_OAUTH_GROUP_CREATION = "true";
      ENABLE_OAUTH_ROLE_MANAGEMENT = "true";
    };
  };
  virtualisation.quadlet.containers.tinyauth.containerConfig.labels."tinyauth.apps.${subdomain}.oauth.groups" =
    lib.mkIf (config.virtualisation.quadlet.containers ? tinyauth) "admin,main";
  services.traefik.dynamicConfigOptions.http = {
    routers.open-webui = {
      rule = "Host(`${subdomain}.${mainaddr}`)";
      service = "open-webui";
      entryPoints = [
        "http"
        "https"
      ];
      middlewares = [ "tinyauth@docker" ];
      tls = { };
    };
    services.open-webui.loadBalancer.servers = [
      {
        url = "http://localhost:${toString config.services.open-webui.port}/";
      }
    ];
  };
}
