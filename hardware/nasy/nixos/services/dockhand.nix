{
  sharesdir,
  genericServiceUser,
  mkTraefikLabels,
  ...
}:
let
  subdomain = "dockhand";
in
{
  services.samba.settings.DockerStacks = {
    path = "${sharesdir}/Stacks/";
    "read only" = "no";
    browseable = "yes";
    "guest ok" = "yes";
    "create mask" = "0644";
    "directory mask" = "0755";
    "fruit:veto_appledouble" = "yes";
    "force user" = genericServiceUser.name;
    "force group" = genericServiceUser.group;
  };
  my.backup-shares = [ "DockerStacks" ];
  virtualisation.quadlet = {
    containers = {
      dockhand = {
        unitConfig = {
          Requires = [ ];
          After = [ ];
        };
        containerConfig = {
          image = "docker.io/fnsys/dockhand:latest";
          environments = {
            DATA_DIR = "${sharesdir}/Stacks";
          };
          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock"
            "${sharesdir}/Stacks:${sharesdir}/Stacks"
          ];
          labels = mkTraefikLabels {
            inherit subdomain;
            application = "dockhand";
            public = true;
            oauth-groups = "admin";
            port = 3000;
          };
        };
      };
    };
  };
}
