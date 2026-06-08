let
  inherit (builtins)
    attrNames
    foldl'
    map
    replaceStrings
    ;
in
{
  age.secrets =
    let
      files = map (replaceStrings [ ".age" ] [ "" ]) (attrNames (import ./secrets.nix));
    in
    foldl' (
      acc: elem: acc // { "${replaceStrings [ "." ] [ "-" ] elem}".file = ./${elem}.age; }
    ) { } files;
}
