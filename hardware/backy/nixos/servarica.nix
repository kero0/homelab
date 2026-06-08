{
  networking = {
    useDHCP = false;
    useNetworkd = true;
    interfaces.enX0 = {
      ipv4.addresses = [
        {
          address = "209.209.10.60";
          prefixLength = 24;
        }
      ];
      ipv4.routes = [
        {
          address = "209.209.10.1";
          prefixLength = 24;
        }
      ];
    };

    defaultGateway = {
      address = "209.209.10.1";
      interface = "enX0";
    };
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };
}
