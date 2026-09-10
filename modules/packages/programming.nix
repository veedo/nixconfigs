{
  flake.nixosModules.programming = { pkgs, ... }: {

    environment.systemPackages = with pkgs; [
      gcc
      gnumake
      cmake
      go
      python3
      nil
      nixpkgs-fmt
    ];

  };
}
