{ config, pkgs, ... }:
{
  services.redis = {
    enable = true;
    settings = {
      port = 6379;
    };
  };


  networking.firewall.allowedTCPPorts = [ 6379 ]; # 8001 ]; # 8001 would be used by RedisInsight,
  # but I don't know how to configure that to deploy that on servers using nix
}