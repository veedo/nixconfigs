{ self, inputs, ... }:
{
  flake.nixosModules.zsh =
    { pkgs, ... }:
    {
      programs.zsh = {
        enable = true;
        enableBashCompletion = true;
        autosuggestions.enable = true;
        syntaxHighlighting.enable = true;
        shellAliases = {
          ll = "ls -l";
          "e." = "dolphin";
        };
        histSize = 1000000;

        ohMyZsh = {
          enable = true;
          plugins = [
            "git"
            "dirhistory"
            "history"
          ];
          custom = "$HOME/.oh-my-zsh/custom/";
          theme = "powerlevel10k/powerlevel10k";
        };
      };
      users.defaultUserShell = pkgs.zsh;
      environment.shells = with pkgs; [ zsh ];

      environment.systemPackages = with pkgs; [
        zsh-fzf-tab
      ];

      programs.fzf = {
        fuzzyCompletion = true;
      };

      fonts.packages = with pkgs; [
        cascadia-code
        fira-code
        iosevka
        jetbrains-mono
        nerd-fonts.fira-code
        nerd-fonts.hasklug
        nerd-fonts.hurmit
        nerd-fonts.jetbrains-mono
        nerd-fonts.meslo-lg
        nerd-fonts.ubuntu
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
      ];
    };
}
