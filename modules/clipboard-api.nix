{ config, pkgs, lib, ... }:

let
  # Derivation for Oracle Instant Client
  oracleInstantClient = pkgs.stdenv.mkDerivation rec {
    name = "oracle-instantclient";
    src = ./instantclient_11_2.zip; # Put your `instantclient_11_2.zip` in the same directory
    nativeBuildInputs = [ pkgs.unzip ];
    installPhase = ''
      mkdir -p $out/lib/instantclient_11_2
      unzip $src -d $out/lib/
    '';
  };

  # Derivation to Build your Node.js API
  clipboardApiPackage = pkgs.stdenv.mkDerivation rec {
    name = "clipboard-api";
    src = ./path/to/your/api/source; # Specify the path to the source code
    buildInputs = [ pkgs.nodejs pkgs.npm pkgs.libaio oracleInstantClient ];

    buildPhase = ''
      export LD_LIBRARY_PATH=${oracleInstantClient}/lib/instantclient_11_2:$LD_LIBRARY_PATH
      cd $src
      npm install
      npm run build
    '';

    installPhase = ''
      mkdir -p $out/dist
      cp -r $src/dist $out/
      cp package*.json $out/
      npm install --production
    '';

    # Make executables available for the systemd service
    meta.description = "Clipboard API backend for Nix";
  };
in
{
  # Add your NixOS systemd service definition to manage the application
  systemd.services.clipboard-api = {
    description = "Clipboard API Service Running NodeJS App";

    # Start the app using the derivation's output
    serviceConfig = {
      Environment = {
        LD_LIBRARY_PATH = "${oracleInstantClient}/lib/instantclient_11_2";
        OCI_HOME = "${oracleInstantClient}/lib/instantclient_11_2";
        OCI_LIB_DIR = "${oracleInstantClient}/lib/instantclient_11_2";
        OCI_INCLUDE_DIR = "${oracleInstantClient}/lib/instantclient_11_2/sdk/include";
        NODE_ENV = "production";
        PORT = "3100"; # API port
      };
      ExecStart = "${pkgs.nodejs}/bin/node ${clipboardApiPackage}/dist/main.js";
      Restart = "always";
    };

    wantedBy = [ "multi-user.target" ]; # Ensure it starts during boot
  };

  # Open port 3100 for external access
  networking.firewall.allowedTCPPorts = [ 3100 ];
}