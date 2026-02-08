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

      systemd.tmpfiles.settings."10-nextcloud-directory"."/clouddata/serverdata/nextcloud".d = {
        group = config.users.users.nextcloud.group;
        user = config.users.users.nextcloud.name;
        mode = "0755";
        age = "-";
      };
      services.nextcloud = {
        enable = true;
        hostName = "cloud.erazander.com";
        database.createLocally = true;
        config = {
          adminuser = "nc_admin";
          dbtype = "mysql";
          adminpassFile = config.age.secrets.cloud_nc_admin.path;
        };
        autoUpdateApps = true;
        maxUploadSize = "1G";
        package = pkgs.nextcloud32;
        https = true;
        caching.redis = true;
        home = "/clouddata/serverdata/nextcloud";
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
