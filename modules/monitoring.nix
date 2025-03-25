{ config, pkgs, ... }:
{
  services.grafana = {
    enable = true;
    settings = {
      security = {
        admin_user = "grafana-admin"; # TODO: use secrets for real details
        admin_email = "example@example.com"; # TODO: use secrets for real details
        admin_password = "password-admin"; # TODO: use secrets for real details
        allow_embedding = true;
      };
      server = {
        # Listening Address
        http_addr = "127.0.0.1";
        # and Port
        http_port = 3500;
        # Grafana needs to know on which domain and URL it's running
        domain = "clipboard.intern.etb"; # TODO: use config variables for this
        root_url = "https://clipboard.intern.etb/grafana/"; # Not needed if it is `https://your.domain/`
        serve_from_sub_path = true;
      };
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
        }
      ];
      dashboards.settings.providers = [{
        name = "Clipboard Dashboards";
        options.path = ../clipboard_server/grafana_provisioning/dashboards;
      }];
    };

#    declarativePlugins = with pkgs.grafanaPlugins; [
#      flant-statusmap-panel
#      grafana-piechart-panel
#    ];
  };

#  services.nginx.virtualHosts.${"clipboard.intern.etb"} = {
#    addSSL = true;
#    enableACME = true;
#    locations."/grafana/" = {
#        proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
#        proxyWebsockets = true;
#        recommendedProxySettings = true;
#    };
#  };

  # Loki for logging
  services.loki = {
    enable = true;
    configFile = ../config/loki-config.yaml;
  };
  # Tempo for distributed tracing
  services.tempo = {
    enable = true;
    configFile = ../config/tempo-config.yaml;
  };

  # OpenTelemetry Collector
  services.opentelemetry-collector = {
    enable = true;
    configFile = ../config/otel-collector-config.yaml;
  };

  # Prometheus for metrics
  services.prometheus = {
    enable = true;
    scrapeConfigs = [
      {
        job_name = "node_exporter";
        static_configs = [{
          targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      }
      # TODO: add the other things, that the old config file had here
    ];

    exporters.node = {
      enable = true;
      port = 9000;
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/monitoring/prometheus/exporters.nix
      enabledCollectors = [ "systemd" ];
      # /nix/store/zgsw0yx18v10xa58psanfabmg95nl2bb-node_exporter-1.8.1/bin/node_exporter  --help
      extraFlags = [ "--collector.ethtool" "--collector.softirqs" "--collector.tcpstat" "--collector.wifi" ];
    };
  };

  # Open the default ports used by OpenTelemetry
  networking.firewall.allowedTCPPorts = [
    4317 # OpenTelemetry gRPC
    4318 # OpenTelemetry HTTP
  ];
}