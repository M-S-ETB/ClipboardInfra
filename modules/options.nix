{ config, lib, pkgs, ... }:

{
  #### Option Definitions ####
  options.clipboardConfig.domainName = lib.mkOption {
    type = lib.types.str;                   # The expected type of the option
    description = "The domain name for the clipboard server";
    default = "example.com";                # Default value if none is set
  };

  options.clipboardConfig.grafanaAdminPassword = lib.mkOption {
    type = lib.types.str;
    description = "The Grafana admin password";
    default = "changeme";                   # Default placeholder, not for production!
    example = "secure-password";
  };

  options.clipboardConfig.grafanaAdminUser = lib.mkOption {
    type = lib.types.str;
    description = "The Grafana admin username";
    default = "admin";                   # Default placeholder, not for production!
    example = "admin";
  };

  options.clipboardConfig.grafanaAdminEmail = lib.mkOption {
    type = lib.types.str;
    description = "The Grafana admin email";
    default = "admin email address";                   # Default placeholder, not for production!
    example = "example@example.com";
  };

  options.clipboardConfig.grafanaLokiConnection = lib.mkOption {
    type = lib.types.str;
    description = "The Grafana Loki connection";
    default = "127.0.0.1:3100";                   # Default placeholder, not for production!
    example = "127.0.0.1:3100";
  };

  options.clipboardConfig.grafanaTempoConnection = lib.mkOption {
    type = lib.types.str;
    description = "The Grafana Tempo connection";
    default = "127.0.0.1:3250";                   # Default placeholder, not for production!
    example = "127.0.0.1:3250";
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