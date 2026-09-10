{
  flake.nixosModules.kitty = { pkgs, lib, ... }: {

    environment.systemPackages = with pkgs; [
      kitty
    ];

    hjem.users.zander = {
      files = {
        ".config/kitty/kitty.conf".source = ./kitty.conf;
      };
    };

  };
}
