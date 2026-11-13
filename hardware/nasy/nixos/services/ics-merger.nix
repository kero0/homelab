{
  pkgs,
  config,
  leaf-inputs,
  configdir,
  genericServiceUser,
  mkTraefikLabels,
  ...
}:
let
  inherit (config.virtualisation.quadlet) builds;
  subdomain = "ics-merger";
  httpPort = 8000;
  appdir = "${configdir}/ics-merger";
  owner = "${toString genericServiceUser.uid}:${toString genericServiceUser.gid}";

  # config.yaml is owned by the container's settings UI, so it is only seeded once.
  seedConfig = pkgs.writeShellScript "ics-merger-seed-config" ''
    set -eu
    mkdir -p ${appdir}/data
    if [ ! -e ${appdir}/config.yaml ]; then
      install -m 0600 ${leaf-inputs.ics-merger}/config.example.yaml ${appdir}/config.yaml
    fi
    chown -R ${owner} ${appdir}
    chmod 0750 ${appdir}
    chmod 0700 ${appdir}/data
  '';
in
{
  age.secrets.ics-merger = {
    inherit (genericServiceUser) name group;
    mode = "0600";
  };

  virtualisation.quadlet = {
    builds.ics-merger.buildConfig = {
      file = "${leaf-inputs.ics-merger}/Dockerfile";
      workdir = "${leaf-inputs.ics-merger}";
    };
    containers.ics-merger = {
      serviceConfig.ExecStartPre = "${seedConfig}";
      containerConfig = {
        image = builds.ics-merger.ref;
        user = toString genericServiceUser.uid;
        group = toString genericServiceUser.gid;
        runInit = true;
        readOnly = true;
        noNewPrivileges = true;
        dropCapabilities = [ "ALL" ];
        tmpfses = [ "/tmp:size=16m,noexec,nosuid" ];
        volumes = [
          "${appdir}/config.yaml:/config/config.yaml"
          "${appdir}/data:/config/data"
          # Reference as `env_file: secrets/providers.env` in config.yaml.
          "${config.age.secrets.ics-merger.path}:/config/secrets/providers.env:ro"
        ];
        # The merged .ics feed must stay unauthenticated for calendar clients.
        labels = mkTraefikLabels {
          inherit subdomain;
          application = "ics-merger";
          port = httpPort;
        };
      };
    };
  };
}
