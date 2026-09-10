{
  flake.nixosModules.core = { pkgs, ... }: {

    nixpkgs.config.allowUnfree = true;
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    #nix.settings = {
    #  substituters = [
    #    "https://cache.nixos.org"
    #    "https://nix-community.cachix.org"
    #    "https://cache.garnix.io"
    #  ];
    #  trusted-public-keys = [
    #    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    #    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCUSeBc="
    #    "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    #  ];
    #};

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.networkmanager.enable = true;

    time.timeZone = "America/Vancouver";
    i18n.defaultLocale = "C.UTF-8";
    i18n.extraLocaleSettings = {
      LC_TIME = "C.UTF-8";
      LC_MONETARY = "en_CA.UTF-8";
    };
    console.keyMap = "us";

    users.defaultUserShell = pkgs.zsh;

    services.getty.autologinUser = "zander";
    users.users.zander = {
      isNormalUser = true;
      description = "Zander";
      extraGroups = [
        "wheel"
        "networkmanager"
        "docker"
      ];
      shell = pkgs.zsh;
      home = "/home/zander";
    };

    environment.loginShellInit = ''
      if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
        exec Hyprland
      fi
    '';

    environment.systemPackages = with pkgs; [
      neovim
      git
      curl
      wget
    ];

    hjem.users = {
      zander = {
        user = "zander";
        directory = "/home/zander";
      };
    };

    system.stateVersion = "25.11";
  };
}
