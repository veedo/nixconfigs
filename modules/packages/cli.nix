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
    programs.starship.enable = true;

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
