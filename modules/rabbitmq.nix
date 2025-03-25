{ config, pkgs, ... }:
{
  services.rabbitmq = {
    enable = true;

    # Exposes UI on port 15672
    managementPlugin.enable = true;
    managementPlugin.port = 15672;
  };

  # Open required ports
  networking.firewall.allowedTCPPorts = [ 5672 15672 ];
}