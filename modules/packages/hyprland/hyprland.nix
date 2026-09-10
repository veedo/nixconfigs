{inputs, ...}:
{
  flake.nixosModules.hyprland = { pkgs, ... }: {

    environment.systemPackages = with pkgs; [
      wl-clipboard wtype
      xdg-desktop-portal-gtk xdg-desktop-portal-gnome
      xwayland-satellite

      grim slurp swappy
      wf-recorder
      brightnessctl
    ];

    programs.hyprland.enable = true;
    programs.hyprland.xwayland.enable = true;
    programs.hyprland.withUWSM = true;
    security.polkit.enable = true;
    services.gnome.gnome-keyring.enable = true;

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    hjem.users.zander = {
      files = {
        ".config/hypr/hyprland.lua".source = ./hyprland.lua;
        ".config/hypr/noctalia.lua".source = ./noctalia.lua;
      };
    };

  };
}
