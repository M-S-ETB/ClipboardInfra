{ config, pkgs, ... }:
{
  services.grafana = {
    enable = true;
    settings = {
      security = {
        allow_embedding = true;
      };
      server = {
        # Listening Address
        http_addr = "0.0.0.0";
        # and Port
        http_port = config.clipboardConfig.grafana.port;
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
        {
          name = "Loki";
          type = "loki";
          url = "http://${config.clipboardConfig.grafana.lokiConnection}";
        }
        {
          name = "Tempo";
          type = "tempo";
          url = "http://${config.clipboardConfig.grafana.tempoConnection}";
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
    config.clipboardConfig.grafana.port # Grafana
  ];
}