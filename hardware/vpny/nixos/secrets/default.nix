let
  inherit (builtins) attrNames listToAttrs map replaceStrings;
  names = map (replaceStrings [ ".age" ] [ "" ]) (attrNames (import ./secrets.nix));
in
{
  age.secrets = listToAttrs (
    map (n: {
      name = n;
      value = {
        file = ./${n}.age;
        owner = "root";
        group = "systemd-network";
        mode = "0440";
      };
    }) names
  );
}
