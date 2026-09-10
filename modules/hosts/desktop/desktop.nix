{ inputs, self, ... }: {
  flake.nixosConfigurations.desktop = inputs.nixpkgs.lib.nixosSystem {
    modules = with self.nixosModules; [
      desktop
    ];
  };


  flake.nixosModules.desktop = {pkgs, ...}: {
    imports = with self.nixosModules; [
      hjem
      # services
      audio
      graphics

      # packages
      hyprland
      core
      nixpkgs
      cli
      noctalia

      kitty
      tmux
      neovim
      zen

      programming
    ];

  };
}
