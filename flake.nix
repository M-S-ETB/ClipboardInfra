{
  description = "A flake for running the ETB Clipboard Client and Server";

  inputs = {
    # Nixpkgs for fetching packages and system modules
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    # Optional: Use specialized modules like RabbitMQ or advanced logging setups from nix community
    # nixosModules.url = "github:nix-community/nixosModules";

    # Nix flake for Client project
    # clipboardClient.url = "path:./../../07_Software/ClipboardClient2";

    # Nix flake for API project
    clipboardApi.url = "path:../../07_Software/Clipboard_API";
  };

  outputs = { self, nixpkgs }@inputs: {
    nixosConfigurations.clipboard = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
      };
      modules = [
        ./modules/options.nix

        #clipboardClient.nixosModule

        # Base system configuration
        {

          # TODO explore better ways to configure things
          clipboardConfig = {
            # required, used for all services
            domainName = "clipboard.intern.etb";

            grafana = {
              # required
              adminUser = "admin";

              # required
              adminEmail = "example@example.com";

              # required
              # TODO: use ENV var or proper secrets of some sort here
              # TODO: look into SOPS for secret management
              adminPassword = "admin";

              # optional, defaults to 3500
              port = 3500;
            };

            api = {
              # optional, defaults to 3100
              port = 3100;

              # optional, enabled by default
              openFirewall = true;
            };

            #optional, defaults to 6379
            redis.port = 6379;
          };
          networking.firewall.allowedTCPPorts = [ 9090 3200 ];
          networking.hostName = "clipboard-server";
        }

        # Development force static network
        {
          networking.interfaces.eth0 = {
            useDHCP = false;
            ipv4.addresses = [
              {
                address = "172.31.153.103"; # Static IP in the subnet
                prefixLength = 20;        # Match the subnet size
              }
            ];
            ipv4.gateway = "172.31.144.1"; # Hyper-V NAT gateway
            # ipv4.dns = [ "8.8.8.8" "8.8.4.4" ]; # Optional DNS
          };
        }

        ./system/configuration.nix

        # NixOS modules to define system services
        ./modules/redis.nix
        ./modules/rabbitmq.nix
        ./modules/monitoring.nix
        ./modules/clipboard-api.nix
        #./modules/clipboard-client.nix

        # reverse proxy setup nginx
        # also hosts clipboard client
        ./modules/clipboard-nginx.nix

        # configuration for nix itself, providing debug output after builds, etc.
        ./modules/nix.nix
      ];
    };
  };
}
