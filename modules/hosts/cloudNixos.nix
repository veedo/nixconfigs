{ inputs, self, ... }:
{
  flake.nixosConfigurations.cloudNixos = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.cloudNixosConfig
      self.nixosModules.commonNixosConfig
    ];
  };
  flake.nixosModules.cloudNixosConfig =
    { config, pkgs, ... }:
    {
      networking.hostName = "cloudnixos"; # Define your hostname.
      users.users.zandere = {
        isNormalUser = true;
        description = "Zander Erasmus";
        extraGroups = [
          "networkmanager"
          "wheel"
          "docker"
          "podman"
        ];
      };

      # Enable automatic login for the user.
      services.getty.autologinUser = "zandere";

      virtualisation.podman.enable = true;

      programs.appimage.enable = true;
      programs.appimage.binfmt = true;

      # List packages installed in system profile. To search, run:
      # $ nix search wget
      environment.systemPackages = with pkgs; [
        gcc
        nixfmt-rfc-style
        openresolv
        python3
        ripgrep
      ];

      #TODO: determine graphics for server
      #hardware.graphics.enable = true;
      #services.xserver.videoDrivers = [ "nvidia" ];

      #TODO: determine power management for server
      #powerManagement.enable = true;

      #TODO: include tailscale?
      #services.tailscale.enable = true;
    };
}
