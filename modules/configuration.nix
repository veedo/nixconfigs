{ self, inputs, ... }:
{
  systems = [ "x86_64-linux" ];
  flake.nixosModules.commonNixosConfig =
    {
      system,
      config,
      pkgs,
      ...
    }:
    {

      imports = [
        self.nixosModules.tmux
        self.nixosModules.desktop
        self.nixosModules.zsh
        self.nixosModules.git
      ];
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Bootloader.
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      #boot.resumeDevice = config.fileSystems."/".device;

      networking.networkmanager.enable = true;

      time.timeZone = "America/Vancouver";
      i18n.defaultLocale = "en_CA.UTF-8";
      console = {
        earlySetup = true;
        packages = with pkgs; [ nerd-fonts.hasklug ];
        font = "${pkgs.nerd-fonts.hasklug}/share/fonts/opentype/NerdFonts/Hasklug/HasklugNerdFont-Medium.otf";
      };

      services.xserver.xkb = {
        layout = "us";
        variant = "";
      };

      # Allow unfree packages
      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search, run:
      # $ nix search wget
      environment.systemPackages = with pkgs; [
        bluetui
        curl
        distrobox
        expect
        firefox
        htop
        hunspell
        hunspellDicts.en_CA
        jq
        keepassxc
        keepassxc-go
        lshw
        neovim
        tree-sitter
        nixfmt-rfc-style
        openresolv
        python3
        ripgrep
        unzip
        vim
        wget
        wgnord
        wireguard-tools
      ];

      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };

      programs.dconf.profiles.user.databases = [
        {
          settings."org/gnome/desktop/interface" = {
            gtk-theme = "Adwaita";
            icon-theme = "Flat-Remix-Red-Dark";
            font-name = "Noto Sans Medium 11";
            document-font-name = "Noto Sans Medium 11";
            monospace-font-name = "Noto Sans Mono Medium 11";
          };
        }
      ];

      hardware.bluetooth.enable = true;

      programs.neovim = {
        enable = true;
        vimAlias = true;
        viAlias = true;
        defaultEditor = true;
      };

      # Some programs need SUID wrappers, can be configured further or are
      # started in user sessions.
      # programs.mtr.enable = true;
      # programs.gnupg.agent = {
      #   enable = true;
      #   enableSSHSupport = true;
      # };

      # List services that you want to enable:
      services.openssh.enable = true;
      services.resolved.enable = true;

      # Open ports in the firewall.
      # networking.firewall.allowedTCPPorts = [ ... ];
      # networking.firewall.allowedUDPPorts = [ ... ];
      # Or disable the firewall altogether.
      # networking.firewall.enable = false;

      # This value determines the NixOS release from which the default
      # settings for stateful data, like file locations and database versions
      # on your system were taken. It‘s perfectly fine and recommended to leave
      # this value at the release version of the first install of this system.
      # Before changing this value read the documentation for this option
      # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
      system.stateVersion = "25.05"; # Did you read the comment?

    };
}
