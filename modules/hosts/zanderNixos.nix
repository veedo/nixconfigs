{ inputs, self, ... }:
{
  flake.nixosConfigurations.zanderNixos = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.zanderNixosHardware
      self.nixosModules.zanderNixosConfig
      self.nixosModules.commonNixosConfig
      self.nixosModules.agenix
      inputs.agenix.nixosModules.default
    ];
  };

  flake.nixosModules.zanderNixosConfig =
    { config, pkgs, ... }:
    {
      networking.hostName = "zandernixos"; # Define your hostname.
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
      virtualisation.docker.enable = true;

      programs.appimage.enable = true;
      programs.appimage.binfmt = true;

      # List packages installed in system profile. To search, run:
      # $ nix search wget
      environment.systemPackages = with pkgs; [
        cargo
        clang-tools
        gcc
        gimp
        libreoffice-qt
        nixfmt-rfc-style
        openresolv
        python3
        ripgrep
        rustc
        teams-for-linux
        vscode
        zig
      ];

      hardware.graphics.enable = true;
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
        modesetting.enable = true;
        # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
        # Enable this if you have graphical corruption issues or application crashes after waking
        # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
        # of just the bare essentials.
        powerManagement.enable = false;
        # Fine-grained power management. Turns off GPU when not in use.
        # Experimental and only works on modern Nvidia GPUs (Turing or newer).
        powerManagement.finegrained = false;
        # Use the NVidia open source kernel module (not to be confused with the
        # independent third-party "nouveau" open source driver).
        # Support is limited to the Turing and later architectures. Full list of
        # supported GPUs is at:
        # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
        # Only available from driver 515.43.04+
        open = true;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        # package = config.boot.kernelPackages.nvidiaPackages.beta;
      };

      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
        dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
        localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
      };

      powerManagement.enable = true;
      systemd.sleep.extraConfig = ''
        AllowSuspend=yes
        AllowHibernation=yes
        AllowHybridSleep=yes
        AllowSuspendThenHibernate=yes
        HibernateDelaySec=30m
      '';

      services.tailscale.enable = true;
    };
}
