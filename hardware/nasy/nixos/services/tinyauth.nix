{
  config,
  lib,
  mainaddr,
  configdir,
  mkTraefikLabels,
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
        labels = mkTraefikLabels {
          subdomain = "pocket-id";
          port = 1411;
          public = true;
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
        image = "docker.io/lldap/lldap:stable";
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
        # Raw LDAP admin UI; only pocket-id needs to reach it, over the
        # container network, never through Traefik or Pangolin.
        labels = mkTraefikLabels {
          subdomain = "lldap";
          port = 17170;
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
        image = "ghcr.io/tinyauthapp/tinyauth:v5";
        environments = {
          TINYAUTH_APPURL = "https://tinyauth.${mainaddr}";
          TINYAUTH_OAUTH_AUTOREDIRECT = "pocketid";
          TINYAUTH_OAUTH_PROVIDERS_POCKETID_AUTHURL = "https://pocket-id.${mainaddr}/authorize";
          TINYAUTH_OAUTH_PROVIDERS_POCKETID_TOKENURL = "https://pocket-id.${mainaddr}/api/oidc/token";
          TINYAUTH_OAUTH_PROVIDERS_POCKETID_USERINFOURL = "https://pocket-id.${mainaddr}/api/oidc/userinfo";
          TINYAUTH_OAUTH_PROVIDERS_POCKETID_REDIRECTURL = "https://tinyauth.${mainaddr}/api/oauth/callback/pocketid";
          TINYAUTH_OAUTH_PROVIDERS_POCKETID_SCOPES = "openid email profile groups";
          TINYAUTH_OAUTH_PROVIDERS_POCKETID_NAME = "Pocket ID";
          TINYAUTH_AUTH_TRUSTEDPROXIES = "172.17.0.0/16";
        };
        volumes = [
          "${configdir}/tinyauth:/data:rw"
          # "/var/run/docker.sock:/var/run/docker.sock"
        ];
        publishPorts = [
          "127.0.0.1:3467:3000"
        ];
        environmentFiles = [
          config.age.secrets.tinyauth-env.path
        ];
        labels =
          mkTraefikLabels {
            subdomain = "tinyauth";
            port = 3000;
            public = false;
          }
          // {
            "traefik.http.middlewares.tinyauth.forwardauth.address" = "http://127.0.0.1:3467/api/auth/traefik";
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
