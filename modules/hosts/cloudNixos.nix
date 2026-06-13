{
  inputs,
  self,
  ...
}:
{
  flake.nixosConfigurations.cloudNixos = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.cloudNixosConfig
      self.nixosModules.commonNixosConfig
      self.nixosModules.cloudNixosHardware
      self.nixosModules.cloudDisks
      inputs.disko.nixosModules.disko
      self.nixosModules.nginx
      self.nixosModules.agenix
      inputs.agenix.nixosModules.default
    ];
  };
  flake.nixosConfigurations.installerCloudNixos = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      ../../installer.nix
      "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    ];
  };
  flake.installerCloudNixos =
    self.nixosConfigurations.installerCloudNixos.config.system.build.isoImage;

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
        widevine-cdm
        (chromium.override { enableWideVine = true; })
      ];

      #TODO: determine graphics for server
      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
          intel-media-driver
          intel-vaapi-driver
        ];
      };
      #services.xserver.videoDrivers = [ "nvidia" ];

      #TODO: determine power management for server
      #powerManagement.enable = true;

      #TODO: include tailscale?
      #services.tailscale.enable = true;

    };

  flake.nixosModules.cloudDisks =
    { config, pkgs, ... }:
    {
      imports = [
        ../../main_disk.nix
        ../../homedrive.nix
        ../../cloud_disk.nix
      ];

      boot.supportedFilesystems = [ "zfs" ];
      #boot.zfs.enabled = true;
      boot.zfs.forceImportRoot = false;
      boot.zfs.extraPools = [ "zclouddata" ];
      services.zfs.autoSnapshot.enable = true;
      services.zfs.trim = {
        enable = true;
        interval = "weekly";
      };
      services.zfs.autoScrub = {
        enable = true;
        interval = "monthly";
        # Scrub all:
        pools = [ ];
      };
      #TODO:? services.zfs.expandOnBoot = "all";
    };
}
