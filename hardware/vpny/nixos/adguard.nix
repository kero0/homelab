{
  my.services.adguardserver = {
    enable = true;
    bind_hosts = [ "10.100.0.1" ];
  };
  boot.kernel.sysctl."net.ipv4.ip_nonlocal_bind" = 1;
}
