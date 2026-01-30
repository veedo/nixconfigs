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

  flake.nixosModules.cloudDisks =
    { config, pkgs, ... }:
    {
      disko.devices = {
        disk = {
          main = {
            type = "disk";
            device = "/dev/sda";
            content = {
              type = "gpt";
              partitions = {
                ESP = {
                  size = "1G";
                  type = "EF00";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                    mountOptions = [ "umask=0077" ];
                  };
                };
                luks = {
                  size = "100%";
                  content = {
                    type = "luks";
                    name = "crypted";
                    extraOpenArgs = [ ];
                    settings = {
                      keyFile = "/dev/sdb";
                      keyFileSize = 4096;
                      allowDiscards = true;
                      fallbackToPassword = true;
                    };
                    content = {
                      type = "lvm_pv";
                      vg = "pool";
                    };
                  };
                };
              };
            };
          };
        };
        lvm_vg = {
          pool = {
            type = "lvm_vg";
            lvs = {
              var = {
                size = "32G";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/var";
                  mountOptions = [
                    "defaults"
                    "noexec"
                    "nodev"
                    "nosuid"
                  ];
                };
              };
              tmp = {
                size = "8G";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/tmp";
                  mountOptions = [
                    "defaults"
                    "noexec"
                    "nodev"
                    "nosuid"
                  ];
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                  mountOptions = [
                    "defaults"
                  ];
                };
              };
              swap = {
                size = "32G";
                content.type = "swap";
              };
              raw = {
                size = "10M";
              };
            };
          };
        };
      };

    };
}
