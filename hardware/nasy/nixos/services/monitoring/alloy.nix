{ config, ... }:
{
  services.alloy = {
    enable = true;
    extraFlags = [
      "--server.http.listen-addr=127.0.0.1:${
        toString (config.services.loki.configuration.server.http_listen_port + 1)
      }"
      "--disable-reporting"
    ];
  };
  environment.etc."alloy/loki.alloy".text = ''
    loki.write "endpoint" {
      endpoint {
        url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push"
      }
    }

    loki.relabel "journal" {
      forward_to = [ ]
      rule {
        source_labels = [ "__journal__systemd_unit" ]
        target_label = "systemd_unit"
      }
      rule {
        source_labels = [ "__journal_syslog_identifier" ]
        target_label = "syslog_identifier"
      }
    }

    loki.source.journal "read"  {
      forward_to = [ loki.write.endpoint.receiver ]
      relabel_rules = loki.relabel.journal.rules
      labels = { component = "loki.source.journal" }
    }

    discovery.relabel "syslog" {
        targets = []

        rule {
            source_labels = ["__syslog_message_hostname"]
            target_label  = "host"
        }

        rule {
            source_labels = ["__syslog_message_hostname"]
            target_label  = "hostname"
        }

        rule {
            source_labels = ["__syslog_message_severity"]
            target_label  = "level"
        }

        rule {
            source_labels = ["__syslog_message_app_name"]
            target_label  = "application"
        }

        rule {
            source_labels = ["__syslog_message_facility"]
            target_label  = "facility"
        }

        rule {
            source_labels = ["__syslog_connection_hostname"]
            target_label  = "connection_hostname"
        }
    }

    loki.source.syslog "syslog" {
        listener {
            address      = "0.0.0.0:1601"
            protocol     = "tcp"
            idle_timeout = "0s"
            use_rfc5424_message = true
            labels       = { job = "syslog", component = "loki.source.syslog", protocol = "tcp" }
            max_message_length = 0
        }
        listener {
            address      = "0.0.0.0:1514"
            protocol     = "udp"
            idle_timeout = "0s"
            use_rfc5424_message = true
            labels       = { job = "syslog", component = "loki.source.syslog", protocol = "udp" }
            max_message_length = 0
        }
        listener {
            address      = "0.0.0.0:1515"
            protocol     = "udp"
            labels       = { job = "syslog", component = "loki.source.syslog", protocol = "udp", cluster="esphome" }
            label_structured_data = true
            syslog_format = "rfc3164"
        }
        forward_to    = [loki.write.endpoint.receiver]
        relabel_rules = discovery.relabel.syslog.rules
    }

  '';
  networking.firewall.allowedUDPPorts = [
    1514
    1515
  ];
  networking.firewall.allowedTCPPorts = [ 1601 ];
}
