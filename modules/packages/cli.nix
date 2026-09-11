{
  flake.nixosModules.cli = { pkgs, lib, ... }: {

    environment.systemPackages = with pkgs; [
      jq
      ripgrep
      fd
      btop
      fzf
      gh
      zip
      unzip
      bat
      dig
      tldr
      fastfetch
      ncdu
      qemu
      zsh-nix-shell
    ];

    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

    };

    programs.yazi.enable = true;
    programs.nh.enable = true;
    programs.starship = {
      enable = true;
      settings = lib.mkMerge [
        (builtins.fromTOML (builtins.readFile "${pkgs.starship}/share/starship/presets/catppuccin-powerline.toml"))
        {
          add_newline = false;
          # Pick your Catppuccin flavor: catppuccin_mocha, catppuccin_macchiato, catppuccin_frappe, or catppuccin_latte
          palette = lib.mkForce "catppuccin_macchiato";

          # (Optional) Add your custom prompt configurations here
          # directory.style = "bg:peach fg:crust";
        }
      ];
    };

    programs.zsh = {
      enable = true;
      # As you type, it suggests commands based on your shell history
      autosuggestions.enable = true;
      # Adds color-coding to commands so you know if they are valid before pressing Enter
      syntaxHighlighting.enable = true;
      # Provides enhanced tab-completion for tools like git, systemd, etc.
      enableBashCompletion = true;

      interactiveShellInit = ''
        eval "$(fzf --zsh)"
        eval $(starship init zsh)
        source ${pkgs.zsh-nix-shell}/share/zsh-nix-shell/nix-shell.plugin.zsh

        # `nixpkgs.config.allowUnfree` only applies to this system's own pkgs;
        # ad-hoc flake refs like `nixpkgs#foo` need NIXPKGS_ALLOW_UNFREE and
        # --impure to honor it (Nix ignores env vars during flake evaluation
        # otherwise). Auto-add --impure for the commands that hit this.
        nix() {
          case "$1" in
            shell|run|build|develop)
              command nix "$1" --impure "''${@:2}"
              ;;
            *)
              command nix "$@"
              ;;
          esac
        }
      '';
    };

    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.git = {
      enable = true;
      config = {
        user.name = "Zander Erasmus";
        user.email = "zerasmus@corvusenergy.com";
        init.defaultBranch = "main";
        core.editor = "nvim";
        pull.rebase = true;
      };
    };

  };
}
