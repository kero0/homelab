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
  '';
}
