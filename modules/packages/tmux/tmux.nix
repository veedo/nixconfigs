{
  flake.nixosModules.tmux = {pkgs, ...}: {

    programs.tmux = {
      enable = true;
      terminal = "tmux-256color";
      baseIndex = 1;
    };


    hjem.users.zander = {
      files = {
        ".config/tmux/tmux.conf".source = ./tmux.conf;
      };
    };

  };
}
