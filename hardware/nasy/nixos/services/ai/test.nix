{
  lib,
  config,
  mainaddr,
  configdir,
  sharesdir,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers;
in
{
  virtualisation.quadlet.containers = {
    ollama = {
      unitConfig = {
        Requires = [
          containers.vpn.ref
        ];
        After = [
          containers.vpn.ref
        ];
      };
      containerConfig = {
        image = "docker.io/ollama/ollama:latest";
        podmanArgs = [
          "--tty"
        ];
        environments = {
        };
        volumes = [
          "${sharesdir}/ollama:/root/.ollama:rw"
        ];
        labels = {
          "traefik.enable" = "false";
        };
        devices = [
          "/dev/dri:/dev/dri:rwm"
          "nvidia.com/gpu=all"
        ];
        logDriver = "journald";
        networks = [
          "container:vpn"
        ];
      };
    };
    open-webui = {
      unitConfig = {
        Requires = [
          containers.vpn.ref
          containers.ollama.ref
        ];
        After = [
          containers.vpn.ref
          containers.ollama.ref
        ];
      };
      containerConfig = {
        image = "ghcr.io/open-webui/open-webui:main";
        environments = {
          OLLAMA_API_BASE_URL = "http://localhost:11434";
          WEBUI_URL = "https://ai.${mainaddr}/";
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

          ENABLE_OTEL = "false";
          ENABLE_OTEL_TRACES = "false";
          ENABLE_OTEL_METRICS = "false";
        };
        volumes = [
          "${configdir}/open-webui:/app/backend/data:rw"
        ];
        labels = {
          "traefik.docker.network" = "vpn";
          "traefik.http.routers.open-webui.rule" = "Host(`ai.${mainaddr}`)";
          "traefik.http.services.open-webui.loadbalancer.server.port" = "8080";
          "traefik.http.routers.open-webui.middlewares" = "tinyauth";
          "tinyauth.apps.ai.oauth.groups" = lib.mkIf (containers ? tinyauth) "admin";
        };
        logDriver = "journald";
        networks = [
          "container:vpn"
        ];
      };
    };
  };
}
