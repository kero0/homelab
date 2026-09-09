{
  config,
  mainaddr,
  ...
}:
let
  httpPort = 3172;
  subdomain = "mealie";
in
{
  services.mealie = {
    enable = true;
    port = httpPort;
    listenAddress = "127.0.0.1";
    database.createLocally = true;
    credentialsFile = config.age.secrets.mealie-env.path;
    settings = {
      BASE_URL = "https://${subdomain}.${mainaddr}";
      TZ = config.time.timeZone;
      ALLOW_SIGNUP = "False";
      TOKEN_TIME = 24 * 180;
      OIDC_AUTH_ENABLED = "True";
      OIDC_SIGNUP_ENABLED = "True";
      OIDC_REMEMBER_ME = "True";
      OIDC_USER_GROUP = "mealie";
      OIDC_ADMIN_GROUP = "mealieadmin";
      OIDC_AUTO_REDIRECT = "True";
      OIDC_PROVIDER_NAME = "PocketID Auth";
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.${subdomain} = {
      rule = "Host(`${subdomain}.${mainaddr}`)";
      service = "${subdomain}";
      entryPoints = [
        "http"
        "https"
      ];
      tls = { };
    };
    services.${subdomain}.loadBalancer.servers = [
      {
        url = "http://localhost:${toString httpPort}/";
      }
    ];
  };
}
