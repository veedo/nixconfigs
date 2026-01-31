{ inputs, self, ... }:
{
  flake.nixosModules.nginx =
    { pkgs, ... }:
    {
      # Can overide ssl in package:
      #services.nginx.package = pkgs.nginxStable.override { openssl = pkgs.libressl; };

      services.nginx.enable = true;

      networking.firewall.allowedTCPPorts = [
        22
        80
        443
      ];

    };

}
