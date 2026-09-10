{
  flake.nixosModules.cli = { pkgs, ... }: {

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
      settings = {
        add_newline = false;
      };
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
