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

      security.acme.acceptTerms = true;
      security.acme.defaults.email = "veedo.a+acme@gmail.com";
    };

}
