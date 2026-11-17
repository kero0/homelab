let
  nasyRecipients =
    (builtins.head (builtins.attrValues (import ../../../nasy/nixos/secrets/secrets.nix))).publicKeys;
  people = builtins.filter (k: builtins.match ".* root@nasy" k == null) nasyRecipients;
  vpny = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILreKLgTBSDdSxwSt0VxGa1jEH+EbZLu71EHNLXJK633 vpny";
  keys = people ++ [ vpny ];
  files = [
    # clients
    "wg0.age"
    # home
    "wg-home.age"
    # nordvpn
    "nord.age"
  ];
in
builtins.listToAttrs (
  map (f: {
    name = f;
    value.publicKeys = keys;
  }) files
)
