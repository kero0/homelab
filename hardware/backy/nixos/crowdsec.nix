{
  services.crowdsec = {
    enable = true;
    hub.collections = [
      "crowdsecurity/linux"
      "crowdsecurity/sshd"
    ];
    localConfig.acquisitions = [
      {
        source = "journalctl";
        journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
        labels.type = "syslog";
      }
    ];
  };

  services.crowdsec-firewall-bouncer.enable = true;
}
