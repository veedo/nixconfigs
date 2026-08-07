{ inputs, self, ... }:
{
  flake.nixosModules.desktop =
    { pkgs, ... }:
    {
      imports = [
        inputs.walker.nixosModules.default
      ];
      disabledModules = [ "services/misc/elephant.nix" ];
      programs.hyprland = {
        enable = true;
        withUWSM = true;
        xwayland.enable = true;
      };
      environment.sessionVariables.NIXOS_OZONE_WL = "1";
      environment.sessionVariables.QT_QPA_PLATFORM = "xcb";

      programs.waybar.enable = true;
      services.elephant.enable = true;

      programs.walker = {
        enable = true;
        config = {
          force_keyboard_focus = false; # forces keyboard forcus to stay in Walker
          close_when_open = true; # close walker when invoking while already opened
          click_to_close = true; # closes walker if clicking outside of the main content area
          as_window = false; # launch walker as a regular window instead of layer shell application
          single_click_activation = true; # activate items with a single click opposed to a double click
          selection_wrap = false; # wrap list if at bottom or top
          global_argument_delimiter = "#"; # query: firefox#https://benz.dev => part after delimiter will be ignored when querying. this should be the same as in the elephant config
          exact_search_prefix = "'"; # disable fuzzy searching
          theme = "default"; # theme to use
          disable_mouse = false; # disable mouse (on input and list only)
          debug = false; # enables debug printing for some stuff, f.e. keybinds
          page_jump_items = 10; # number of items to skip with Page Up/Down
          hide_quick_activation = false; # globally hide the quick activation buttons
          hide_action_hints = false; # globally hide the action hints
          hide_action_hints_dmenu = true; # hide the actions hints for dmenu
          hide_return_action = false; # hide actions that are bound to Return
          keybind_symbols = true; # render keybind hints with key symbols (e.g. ⌃+⏎) instead of plain text ("ctrl Return")
          resume_last_query = false; # open walker with the last query in place
          actions_as_menu = false; # display all possible actions in a submenu
          placeholders."default" = {
            input = "Search";
            list = "No Results";
          };
          empty = [
            "desktopapplications"
            "runner"
          ];
          providers.prefixes = [
          ];
          keybinds.quick_activate = [
            "F1"
            "F2"
            "F3"
            "F4"
            "F5"
            "F6"
            "F7"
            "F8"
            "F9"
          ];
          emergencies = [
            {
              text = "suspend";
              command = "systemctl suspend";
            }
          ];
        };
      };

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

    };
}
