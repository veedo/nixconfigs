{
  description = "System flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  # outputs =
  #   {
  #     self,
  #     nixpkgs,
  #     nixpkgs-unstable,
  #     ...
  #   }@inputs:
  #   let
  #     system = "x86_64-linux";
  #   in
  #   {
  #     packages = import ./pkgs nixpkgs.legacyPackages.${system};
  #     overlays = import ./overlays { inherit inputs; };
  #     nixosModules = import ./modules/nixos;
  #     nixpkgs.config.allowUnfree = true;
  #     nixosConfigurations.zandernixos = nixpkgs.lib.nixosSystem {
  #     };
  #   };
}
