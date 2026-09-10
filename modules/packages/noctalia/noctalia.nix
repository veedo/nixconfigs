{ inputs, ... }: {
  flake.nixosModules.noctalia = { pkgs, lib, ... }: {
    # `programs.noctalia` isn't in nixos-26.05 (stable) yet, only in nixpkgs-unstable.
    # The module is self-contained, so import it directly rather than pulling in
    # all of nixpkgs-unstable's module set.
    imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/programs/wayland/noctalia.nix" ];

    environment.systemPackages = with pkgs; [
      noctalia
    ];

    programs.noctalia = {
      enable = true;
      recommendedServices.enable = true;
      systemd.enable = true;
    };

    services.tuned.enable = true;
    services.upower.enable = true;
  };
}
