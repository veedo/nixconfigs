{ inputs, ... }: {
  flake.nixosModules.noctalia = { pkgs, lib, ... }: {

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
