{ config, pkgs, ... }:
{
  options.clipboardConfig.redis = {
      port = lib.mkOption {
        type = lib.types.int;
        description = "The port used for redis";
        default = 6379;
      };
  };

  config = {
    services.redis = {
      enable = true;
      settings = {
        port = config.clipboardConfig.redis.port;
      };
    };

    # ---------------------
    # Podman for redisInsight
    # RedisInsight is not in nixpkgs, probably due to licensing reasons.
    # Use its container image instead, to deploy on servers.
    # ---------------------

#    # Enable Podman
#    virtualisation.podman.enable = true;
#
#    # Fetch the RedisInsight container image
#    environment.systemPackages = with pkgs; [
#      dockerTools.pullImage {
#        imageName = "redis/redisinsight";
#        imageDigest = "sha256:019fcf7746316312474c2f347a9ee21797a8cb48ebaacb50f3000b4be08a468e";
#        finalImageName = "redisinsight";
#        finalImageTag = "2.68";
#        #sha256 = "0000000000000000000000000000000000000000000000000000000000000000"; # Replace with actual sha256 digest
#      }
#    ];
#
#    # Make redisinsight data dir (what data does it need to store? idk)
#    environment.etc."redisinsight".source = pkgs.runCommand "make-redisinsight-dir" {} ''
#      mkdir -p /var/lib/redisinsight
#    '';
#
#    # Create RedisInsight systemd unit, using local image, downloaded in previous step
#    systemd.services.redisinsight = {
#      description = "RedisInsight Podman Container";
#      after = [ "network.target" "podman.service" ];
#      requires = [ "podman.service" ];
#
#      serviceConfig = {
#        ExecStart = ''
#          /run/current-system/sw/bin/podman load < ${pkgs.dockerTools.pullImage {
#            imageName = "redis/redisinsight";
#            imageTag = "latest";
#            sha256 = "0000000000000000000000000000000000000000000000000000000000000000"; # Replace with actual sha256
#          }}
#          /run/current-system/sw/bin/podman run \
#          --name=redisinsight \
#          --rm \
#          -p 8001:5540 \
#          -v /var/lib/redisinsight:/db \
#          redis/redisinsight:latest
#        '';
#        ExecStop = "/run/current-system/sw/bin/podman stop redisinsight";
#        Restart = "always";
#      };
#
#      wantedBy = [ "multi-user.target" ];
#    };


    networking.firewall.allowedTCPPorts = [
      config.clipboardConfig.redis.port
#      8001 # redisInsight
    ];
  };
}