{ config, lib, pkgs, ... }:

{
  #### Option Definitions ####
  options.clipboardConfig = {
    domainName = lib.mkOption {
      type = lib.types.str;
      description = "The domain name for the clipboard server";
      default = "example.com";
    };

    grafana = {
      adminPassword = lib.mkOption {
        type = lib.types.str;
        description = "The Grafana admin password";
        default = "changeme";
        example = "secure-password";
      };

      adminUser = lib.mkOption {
        type = lib.types.str;
        description = "The Grafana admin username";
        default = "admin";
        example = "admin";
      };

      adminEmail = lib.mkOption {
        type = lib.types.str;
        description = "The Grafana admin email";
        default = "admin email address";
        example = "example@example.com";
      };

      port = lib.mkOption {
        type = lib.types.int;
        description = "The port used for grafana";
        default = 3100;
      };

      lokiConnection = lib.mkOption {
        type = lib.types.str;
        description = "The Grafana Loki connection";
        default = "127.0.0.1:3100";
        example = "127.0.0.1:3100";
      };

      tempoConnection = lib.mkOption {
        type = lib.types.str;
        description = "The Grafana Tempo connection";
        default = "127.0.0.1:3250";
        example = "127.0.0.1:3250";
      };
    };
  };

  #### Apply Options ####
  config = {
    services.grafana.settings.server.domain = config.clipboardConfig.domainName;
    services.grafana.settings.server.root_url = "https://${config.clipboardConfig.domainName}/grafana/"; # Not needed if it is `https://your.domain/`

    services.grafana.settings.security.admin_user = config.clipboardConfig.grafanaAdminUser;
    services.grafana.settings.security.admin_email = config.clipboardConfig.grafanaAdminEmail;
    services.grafana.settings.security.admin_password = config.clipboardConfig.grafanaAdminPassword;

  };
}