{
  flake.nixosModules.cli = { pkgs, ... }: {

    environment.systemPackages = with pkgs; [
      jq ripgrep fd btop fzf gh
      zip unzip bat dig tldr fastfetch ncdu
      qemu
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
    programs.zoxide.enable = true;

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
