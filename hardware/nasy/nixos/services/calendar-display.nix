{
  pkgs,
  leaf-inputs,
  config,
  lib,
  mainaddr,
  ...
}:
let
  httpPort = 3181;
  subdomain = "calendar";
  tinyauth = false;
in
{
  systemd = {
    timers.calendar-display-usr1 = {
      description = "Calendar Display Service Timer";
      wantedBy = [ "timers.target" ];
      requires = [
        "calendar-display-usr1.service"
        "calendar-display.service"
      ];
      after = [ "calendar-display.service" ];
      timerConfig = {
        OnCalendar = "*-*-* *:0/5:00";
        Persistent = true;
      };
    };
    services = {
      calendar-display-usr1 = {
        description = "Calendar Display Service refresh";
        serviceConfig = {
          ExecStart = "systemctl kill --signal=USR1 calendar-display.service";
          Type = "oneshot";
        };
      };
      calendar-display = {
        description = "Calendar Display Service";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        startLimitIntervalSec = 60;
        startLimitBurst = 3;
        environment = {
          LISTEN_ADDRESS = "127.0.0.1";
          LISTEN_PORT = toString httpPort;
        };
        serviceConfig = {
          EnvironmentFile = config.age.secrets.calendar-display.path;
          ExecStart = "${leaf-inputs.calendar-display.server.${pkgs.system}}/bin/calendar-display-server";
          Restart = "on-failure";
          KillMode = "process";
        };
      };
    };
  };

  virtualisation.quadlet.containers.tinyauth.containerConfig.labels."tinyauth.apps.${subdomain}.oauth.groups" =
    lib.mkIf tinyauth "admin,main";
  services.traefik.dynamicConfigOptions.http = {
    routers.${subdomain} = {
      rule = "Host(`${subdomain}.${mainaddr}`)";
      service = "${subdomain}";
      entryPoints = [
        "http"
        "https"
      ];
      middlewares = lib.lists.optional tinyauth "tinyauth@docker";
      tls = { };
    };
    services.${subdomain}.loadBalancer.servers = [
      {
        url = "http://localhost:${toString httpPort}/";
      }
    ];
  };
}
