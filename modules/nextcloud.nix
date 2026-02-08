{ inputs, self, ... }:
{
  flake.nixosModules.nextcloud =
    { config, pkgs, ... }:
    {
      imports = [
        self.nixosModules.nginx
      ];
      environment.systemPackages = with pkgs; [
      ];

      age.secrets.cloud_nc_admin = {
        file = ./secrets/cloud/nc_admin.age;
        publicKeys = [ self.agenix.cloud_secrets ];
      };

      services.mysql = {
        enable = true;
        package = pkgs.mariadb;
      };

      services.nextcloud = {
        enable = true;
        hostName = "cloud.erazander.com";
        database.createLocally = true;
        config = {
          adminuser = "nc_admin";
          dbtype = "mysql";
          adminpassFile = "/var/lib/nextcloud/admin-pass";
        };
        autoUpdateApps = true;
        maxUploadSize = "1G";
        package = pkgs.nextcloud32;
        https = true;
        adminpassFile = config.age.secrets.cloud_nc_admin.path;
        caching.redis = true;
      };

      services.nginx.virtualHosts."cloud.erazander.com" = {
        #listen = [
        #  {
        #    addr = "127.0.0.1";
        #    port = 8081;
        #  }
        #];

        enableACME = true;
        forceSSL = true;
      };

    };
}
