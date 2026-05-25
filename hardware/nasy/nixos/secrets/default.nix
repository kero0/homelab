{ lib, config, ... }:
let
  inherit (builtins)
    attrNames
    foldl'
    map
    replaceStrings
    ;
in
{
  age =
    lib.recursiveUpdate
      {
        secrets =
          let
            files = map (replaceStrings [ ".age" ] [ "" ]) (attrNames (import ./secrets.nix));
          in
          foldl' (
            acc: elem: acc // { "${lib.strings.replaceStrings [ "." ] [ "-" ] elem}".file = ./${elem}.age; }
          ) { } files;
      }
      {
        secrets.immich-config = {
          owner = config.users.users.serviceuser.name;
          group = config.users.groups.services.name;
        };
        secrets.immich-test-config = {
          owner = config.users.users.serviceuser.name;
          group = config.users.groups.services.name;
        };
      };
}
