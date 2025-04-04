# clipboard-nginx.nix
{ config, pkgs, lib, ... }:

let
  # Import the Clipboard Angular Client build
  #clipboardClient = import ./clipboard-client.nix { inherit pkgs; };

  # Path to the static `config.json` file
  configJson = ../config.json;

  # Definitions of proxy backends for various services
  clipboardProxyServices = ''
    # Reverse proxy for Clipboard API
    location /api/ {
      proxy_pass http://localhost:3100/;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
    }

    # Reverse proxy for Grafana
    location /grafana/ {
      proxy_pass http://localhost:3000/;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
    }

    # Reverse proxy for RabbitMQ Management UI
    location /message-queue/ {
      proxy_pass http://localhost:15672/;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
    }

    # Add any other reverse proxies for your services
    # Example: Redis insight, Loki, etc.
    location /redis-insight/ {
      proxy_pass http://localhost:8001/;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
    }
  '';
in
{
  # Enable and configure Nginx.
  services.nginx = {
    enable = true;

    virtualHosts."clipboard-client" = {
      # Root for serving the Angular client
      root = ../system; # clipboardClient;

      serverName = config.clipboardConfig.domainName;

      listen = [
        { port = 443; ssl = true; addr = "[::]"; }
        { port = 80; ssl = false; addr = "[::]"; }
      ];
      forceSSL = true; # Redirect HTTP to HTTPS

      # SSL Configuration
      sslCertificate = ../certs/clipboard.pem;  # Path to your SSL cert
      sslCertificateKey = ../certs/clipboard.key;  # Path to private key

#      locations = [
#        ""
#      ];

      # Serve the static `config.json` and handle routes
      extraConfig = ''
        # Serve the Angular client
        index index.html;
        location / {
          try_files $uri $uri/ /index.html;
        }

        # Serve the config.json file
        location /config.json {
          root ${configJson};
          default_type application/json;
        }

        # Define reverse proxy configurations
        ${clipboardProxyServices}
      '';
    };
  };

  # Open required ports for Nginx (443 for HTTPS)
  networking.firewall.allowedTCPPorts = [ 443 ];
}