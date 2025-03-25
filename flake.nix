{
  description = "A flake for running the ETB Clipboard Client and Server";

  inputs = {
    # Nixpkgs for fetching packages and system modules
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    # Optional: Use specialized modules like RabbitMQ or advanced logging setups from nix community
    # nixosModules.url = "github:nix-community/nixosModules";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.clipboard = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./system/configuration.nix

        # Base system configuration
        {
          nix.settings.experimental-features = [ "nix-command" "flakes" ];
          networking.firewall.allowedTCPPorts = [ 9090 3000 3100 3200 3500 ];
          networking.hostName = "clipboard-server";
        }

        # NixOS modules to define system services
        ./modules/redis.nix
        ./modules/rabbitmq.nix
        ./modules/monitoring.nix
        #./modules/clipboard-api.nix

        # reverse proxy setup nginx
        # also hosts clipboard client
        ./modules/clipboard-nginx.nix

        # configuration for nix itself, providing debug output after builds, etc.
        ./modules/nix.nix
      ];
    };
  };
}
