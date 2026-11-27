{
  clients = {
    subnet = "10.100.0.0/24";
    address = "10.100.0.1/24";
    port = 51820;
    publicKey = "eWJteanWAAZtFj1MokfA9+gfCqeA5doAfV2vuMZp61A=";
    endpoint = "163.192.192.83:51820";
    loopback = "10.7.0.1";
    bypass = [
      "10.0.0.0/8"
      "192.168.0.0/16"
      "127.0.0.0/8"
    ];
    dns = [
      "10.5.10.229"
      "10.100.0.1"
    ];
    peers = map (f: import (./clients + "/${f}")) (
      builtins.filter (f: builtins.match ".*\\.nix" f != null) (
        builtins.attrNames (builtins.readDir ./clients)
      )
    );
  };

  home = rec {
    address = "10.200.0.2/32";
    publicKey = "seERzLaJnI0z7x0MKb+UO4BeiBvhH9Tfj8amxJ/ueHM=";
    endpoint = "whvdjs.duckdns.org:51821";
    port = 51821;
    lan = [
      "10.5.10.0/24"
      "10.65.10.0/24"
    ];
    dns = [
      "10.5.10.229"
    ];
    routerSubnet = "10.200.0.0/24";
    routes = lan ++ [ routerSubnet ];
  };

  nord = {
    address = "10.5.0.2/32";
    publicKey = "NPq/jzXUxvXuzLpZ99ln1EiLcsfZCpjh123acSXZSj0=";
    endpoint = "ca1966.nordvpn.com:51820";
    dns = [
      "103.86.96.100"
      "103.86.99.100"
    ];
  };
}
