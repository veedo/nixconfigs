{ inputs, self, ... }:
{
  flake.nixosModules.nextcloud =
    { config, pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
      ];

      age.secrets.cloud_nc_admin = {
        file = ./secrets/cloud/nc_admin.age;
        publicKeys = [ self.agenix.cloud_secrets ];
      };

      services.nextcloud = {
        enable = true;
        hostName = "localhost";
        autoUpdateApps = true;
        maxUploadSize = "1G";
        package = pkgs.nextcloud32;
        https = true;
        adminpassFile = config.age.secrets.cloud_nc_admin.path;
        settings = {
          trusted_domains = [
            "http://cloud.erazander.com"
            "https://cloud.erazander.com"
          ];
        };
      };

      services.nginx.virtualHosts."cloud.erazander.com".listen = [
        {
          addr = "127.0.0.1";
          port = 8081;
        }
      ];

    };
}
