{ inputs, self, ... }:
{
  flake.nixosModules.nginx.proxyManager =
    { pkgs, ... }:
    {
      # Can overide ssl in package:
      #services.nginx.package = pkgs.nginxStable.override { openssl = pkgs.libressl; };

      virtualisation.containers.enable = true;
      virtualisation.podman.enable = true;
      virtualisation.oci-containers.backend = "podman";
      defaultNetwork.settings.dns_enabled = true;

      environment.systemPackages = with pkgs; [
        dive # look into docker image layers
        podman-tui # status of containers in the terminal
        podman-compose # start group of containers for dev
      ];

      virtualisation.oci-containers.containers.nginx-proxy-manager = {
        image = "jc21/nginx-proxy-manager:latest";
        user = "1000:100";
        ports = [
          "80:80" # HTTP access
          "443:443" # HTTPS access
          "81:81" # NPM Admin interface access
        ];
        volumes = [
          "/var/lib/nginx-proxy-manager/data:/data"
          "/var/lib/nginx-proxy-manager/letsencrypt:/etc/letsencrypt"
        ];
        environment = {
          PUID = "1000";
          PGID = "100";
          TZ = "America/Vancouver";
        };
        # Ensure necessary services like the database are running if using network segmentation
        # networks = [ "your_custom_network" ];
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
        81
      ];

      # Ensure the necessary directories exist on the host filesystem
      systemd.services.create-npm-dirs = {
        wantedBy = [ "multi-user.target" ];
        before = [ "virtualisation-oci-containers.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''
            ${pkgs.coreutils}/bin/mkdir -p /var/lib/nginx-proxy-manager/data
            ${pkgs.coreutils}/bin/mkdir -p /var/lib/nginx-proxy-manager/letsencrypt
            # Optional: Set ownership if using PUID/PGID
            # ${pkgs.coreutils}/bin/chown -R 1000:100 /var/lib/nginx-proxy-manager
          '';
        };
      };
    };
}
