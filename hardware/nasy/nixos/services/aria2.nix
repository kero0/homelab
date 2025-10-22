{
  lib,
  config,
  pkgs,
  mainaddr,
  configdir,
  sharesdir,
  ...
}:
{
  virtualisation.oci-containers.containers.aria2 =
    let
      port = toString 6800;
    in
    {
      image = "localhost/aria2:latest";
      imageStream = pkgs.dockerTools.streamLayeredImage {
        name = "aria2";
        tag = "latest";
        contents = [
          pkgs.aria2
          pkgs.cacert
        ];
        config = {
          Cmd = [
            "aria2c"
            "--conf-path=/config/aria2.conf"
          ];
          Env = [ "PATH=/usr/bin:/bin" ];
        };
      };
      environment = {
        "TZ" = config.time.timeZone;
      };
      volumes = [
        "${sharesdir}/Downloads:/downloads:rw"
        "${sharesdir}/Games:/games:rw"
        "${sharesdir}/Movies:/movies:rw"
        "${sharesdir}/Other:/other:rw"
        "${sharesdir}/TV:/tv:rw"
        "${configdir}/aria2-config:/config:rw"
      ];
      labels = {
        "traefik.docker.network" = "vpn";
        "traefik.http.services.aria2.loadbalancer.server.port" = port;
      };
      dependsOn = [
        "vpn"
      ];
      user = "${toString config.users.users.serviceuser.uid}:${toString config.users.groups.services.gid}";
      log-driver = "journald";
      extraOptions = [
        "--network=container:vpn"
      ];
    };
  virtualisation.oci-containers.containers."ariang" = {
    image = "localhost/ariang:latest";
    imageStream = pkgs.dockerTools.streamLayeredImage {
      name = "ariang";
      tag = "latest";
      contents = [
        # Set up users and groups
        (pkgs.writeTextDir "etc/shadow" ''
          root:!x:::::::
          nginx:!:::::::
        '')
        (pkgs.writeTextDir "etc/passwd" ''
          root:x:0:0::/root:${pkgs.runtimeShell}
          nginx:x:999:999::/home/nginx:
        '')
        (pkgs.writeTextDir "etc/group" ''
          root:x:0:
          nginx:x:999:
        '')
        (pkgs.writeTextDir "etc/gshadow" ''
          root:x::
          nginx:x::
        '')

        (pkgs.writeTextDir "var/cache/nginx/.keep" "")
        (pkgs.writeTextDir "var/log/nginx/.keep" "")
        (pkgs.writeTextDir "tmp/nginx_client_body/.keep" "")
        pkgs.bash
      ];
      enableFakechroot = true;
      config = {
        Cmd =
          let
            src' = builtins.fetchurl {
              url = "https://github.com/mayswind/AriaNg/releases/download/1.3.11/AriaNg-1.3.11-AllInOne.zip";
              sha256 = "0ax4l3ya62jw657qwvcrjqizkj6344syf94m61z5rwv1d0b87gmk";
            };
            src = pkgs.runCommand "ariang-src" { } ''
              mkdir -p $out
              ${pkgs.unzip}/bin/unzip ${src'} -d $out
            '';
          in
          [
            "${pkgs.nginx}/bin/nginx"
            "-c"
            (pkgs.writeText "nginx.conf" ''
              user nginx nginx;
              daemon off;
              events {}
              http {
                server {
                  listen 80;
                  location / {
                    root ${src}/;
                  }
                }
              }
            '')
          ];
        Env = [ "PATH=/usr/bin:/bin" ];
        WorkingDir = "/usr/share/ariang";
      };
    };
    labels = {
      "traefik.docker.network" = "vpn";
      "traefik.http.routers.ariang.rule" = "Host(`downloader.${mainaddr}`)";
      "traefik.http.services.ariang.loadbalancer.server.port" = "80";
    };
    dependsOn = [
      "vpn"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network=container:vpn"
    ];
  };
}
