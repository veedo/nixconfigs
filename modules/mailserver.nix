{ inputs, self, ... }:
{
  flake.nixosModules.mailserver =
    { config, pkgs, ... }:
    {
      imports = [
        (builtins.fetchTarball {
          # Pick a release version you are interested in and set its hash, e.g.
          url = "https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/archive/nixos-25.05/nixos-mailserver-nixos-25.05.tar.gz";
          # release="nixos-25.05"; nix-prefetch-url "https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/archive/${release}/nixos-mailserver-${release}.tar.gz" --unpack
          sha256 = "0la8v8d9vzhwrnxmmyz3xnb6vm76kihccjyidhfg6qfi3143fiwq";
        })
      ];

      security.acme = {
        acceptTerms = true;
        defaults.email = "security@erazander.com";
        certs.${config.mailserver.fqdn} = {
          # Further setup required, check the manual:
          # https://nixos.org/manual/nixos/stable/#module-security-acme
        };
      };

      mailserver = {
        enable = true;
        stateVersion = 3;
        fqdn = "mail.erazander.com";
        domains = [ "erazander.com" ];

        # reference an existing ACME configuration
        x509.useACMEHost = config.mailserver.fqdn;

        # A list of all login accounts. To create the password hashes, use
        # nix-shell -p mkpasswd --run 'mkpasswd -s'
        loginAccounts = {
          "zander@erazander.com" = {
            # TODO: use temp password for now, change to use age secrets
            hashedPassword = "$y$j9T$kH36yhbMhTkhEA.azcjAm0$2Mw1x.EugW4lykwDiYDbsxNijJsVuw4pkPASkUjjsoC";
            aliases = [ "postmaster@erazander.com" ];
          };
          "meagan@erazander.com" = {
            # ...
          };
        };
      };
    };
}
