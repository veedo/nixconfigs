{ pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.QT_QPA_PLATFORM = "xcb";

  programs.waybar.enable = true;

  environment.systemPackages = with pkgs; [
    adwaita-qt6
    cava
    flat-remix-icon-theme
    grim
    hyprpolkitagent
    kdePackages.dolphin
    kdePackages.kio-extras
    kdePackages.kio-fuse
    kdePackages.qtsvg
    kitty
    libnotify
    libqalculate
    nordzy-cursor-theme
    pavucontrol
    playerctl
    rose-pine-hyprcursor
    slurp
    swappy
    swaybg
    swaynotificationcenter
    walker
    waytrogen
    wl-clipboard
  ];

  security.sudo.extraRules = [
    {
      users = [ "zandere" ];
      commands = [
        {
          command = "/home/zandere/.config/waybar/scripts/vpn_status.sh";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/home/zandere/.config/waybar/scripts/update_system.sh";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

}
