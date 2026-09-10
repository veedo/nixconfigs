{inputs, ...}: {

  #flake-file.inputs ={
  #  noctalia = {
  #    url = "github:noctalia-dev/noctalia-shell";
  #    inputs.nixpkgs.follows = "nixpkgs";
  #    inputs.noctalia-qs.follows = "noctalia-qs";
  #  };
  #  noctalia-qs = {
  #    url = "github:noctalia-dev/noctalia-qs";
  #    inputs.nixpkgs.follows = "nixpkgs";
  #  };
  #};
  flake.nixosModules.noctalia = {pkgs, lib, ...}: {

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
#
#    hjem.users.zander = {
#      files = {
#        ".config/noctalia-shell/config.json".source = ./noctalia.json;
#      };
#    };

  };
}

