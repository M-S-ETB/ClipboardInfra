{ pkgs }:

pkgs.stdenv.mkDerivation rec {
  name = "clipboard-client";
  src = ./path/to/your/client/source; # Replace with the path to your client source code

  buildInputs = [
    pkgs.nodejs-20
    pkgs.yarn # Use yarn if the package.json specifies it
  ];

  buildPhase = ''
    # Install dependencies
    npm install

    # Install Angular CLI globally
    npm install -g @angular/cli

    # Build the client using Angular
    ng build --configuration release-domain
  '';

  installPhase = ''
    mkdir -p $out
    cp -r dist/clipboard_client2/browser/* $out/
  '';

  meta = {
    description = "Clipboard Client Build (Static Files for NGINX)";
  };
}