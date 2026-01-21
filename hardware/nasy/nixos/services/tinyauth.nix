{
  config,
  lib,
  pkgs,
  mainaddr,
  configdir,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers;
in
{
  options.my.auth-headers =
    let
      inherit (lib) mkOption;
      inherit (lib.types) str;
    in
    {
      user = mkOption {
        type = str;
        default = "Remote-User";
      };
      email = mkOption {
        type = str;
        default = "Remote-Email";
      };
      name = mkOption {
        type = str;
        default = "Remote-Name";
      };
      groups = mkOption {
        type = str;
        default = "Remote-Groups";
      };
    };
  config.virtualisation.quadlet.containers = {
    pocket-id = {
      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";
      };
      unitConfig = {
        Requires = [
          containers.lldap.ref
        ];
        After = [
          containers.lldap.ref
        ];
      };
      containerConfig = {
        image = "ghcr.io/pocket-id/pocket-id:v2";
        environments = rec {
          APP_URL = "https://pocket-id.${mainaddr}";
          TRUST_PROXY = "true";
          PORT = "1411";
          ANALYTICS_DISABLED = "true";
          LDAP_ENABLED = "true";
          LDAP_URL = "ldap://lldap:3890";
          LDAP_BASE = containers.lldap.containerConfig.environments.LLDAP_LDAP_BASE_DN;
          LDAP_BIND_DN = "uid=admin,ou=people,${LDAP_BASE}";
          LDAP_USER_SEARCH_FILTER = "(objectClass=person)";
          LDAP_USER_GROUP_SEARCH_FILTER = "(objectClass=groupOfNames)";
          LDAP_SKIP_CERT_VERIFY = "true";
          LDAP_SOFT_DELETE_USERS = "false";
          LDAP_ATTRIBUTE_USER_UNIQUE_IDENTIFIER = "uuid";
          LDAP_ATTRIBUTE_USER_USERNAME = "uid";
          LDAP_ATTRIBUTE_USER_EMAIL = "mail";
          LDAP_ATTRIBUTE_USER_FIRST_NAME = "givenName";
          LDAP_ATTRIBUTE_USER_LAST_NAME = "sn";
          LDAP_ATTRIBUTE_USER_PROFILE_PICTURE = "jpegPhoto";
          LDAP_ATTRIBUTE_GROUP_MEMBER = "member";
          LDAP_ATTRIBUTE_GROUP_UNIQUE_IDENTIFIER = "uuid";
          LDAP_ATTRIBUTE_GROUP_NAME = "cn";
          LDAP_ADMIN_GROUP_NAME = "_pocket_id_admins";
          UI_CONFIG_DISABLED = "true";
        };
        labels = {
          "traefik.http.services.pocket-id.loadbalancer.server.port" = "1411";
        };
        volumes = [
          "${configdir}/pocket-id/data:/app/data"
        ];
        environmentFiles = [
          config.age.secrets.pocket-id-env.path
        ];
        logDriver = "journald";
      };
    };
    lldap = {
      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";
      };
      containerConfig = {
        image = "lldap/lldap:stable";
        environments = {
          APP_URL = "https://pocket-id.${mainaddr}";
          GID = "${toString config.users.groups.services.gid}";
          UID = "${toString config.users.users.serviceuser.uid}";
          TZ = config.time.timeZone;
          LLDAP_LDAP_BASE_DN = "dc=" + lib.concatStringsSep ",dc=" (lib.splitString "." mainaddr);
        };
        volumes = [
          "${configdir}/lldap/data:/data"
        ];
        environmentFiles = [
          config.age.secrets.lldap-env.path
        ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.services.lldap.loadbalancer.server.port" = "17170";
        };
        logDriver = "journald";
      };
    };
    tinyauth = {
      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";
      };
      unitConfig = {
        Requires = [
          containers.lldap.ref
        ];
        After = [
          containers.lldap.ref
        ];
      };
      containerConfig = {
        image = "ghcr.io/steveiliop56/tinyauth:v4";
        environments = {
          APP_URL = "https://tinyauth.${mainaddr}";
          OAUTH_AUTO_REDIRECT = "pocketid";
          PROVIDERS_POCKETID_AUTH_URL = "https://pocket-id.${mainaddr}/authorize";
          PROVIDERS_POCKETID_TOKEN_URL = "https://pocket-id.${mainaddr}/api/oidc/token";
          PROVIDERS_POCKETID_USER_INFO_URL = "https://pocket-id.${mainaddr}/api/oidc/userinfo";
          PROVIDERS_POCKETID_REDIRECT_URL = "https://tinyauth.${mainaddr}/api/oauth/callback/pocketid";
          PROVIDERS_POCKETID_SCOPES = "openid email profile groups";
          PROVIDERS_POCKETID_NAME = "Pocket ID";
        };
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
        ];
        environmentFiles = [
          config.age.secrets.tinyauth-env.path
        ];
        labels = {
          "traefik.http.services.tinyauth.loadbalancer.server.port" = "3000";
          "traefik.http.middlewares.tinyauth.forwardauth.address" =
            "https://tinyauth.${mainaddr}/api/auth/traefik";
          "traefik.http.middlewares.tinyauth.forwardauth.authResponseHeaders" = lib.concatStringsSep "," (
            with config.my.auth-headers;
            [
              user
              email
              name
              groups
            ]
          );
        };
        logDriver = "journald";
      };
    };
  };
}
