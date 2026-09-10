{ inputs, ... }:
{
  flake-file.inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.xz";
    nixpkgs-unstable.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz";
  };

  flake.nixosModules.nixpkgs = { pkgs, ... }: {
    nixpkgs.config.allowUnfree = true;

    # Exposes pkgs.unstable.<name> for use anywhere in the nix config.
    nixpkgs.overlays = [
      (final: prev: {
        unstable = import inputs.nixpkgs-unstable {
          system = prev.stdenv.hostPlatform.system;
          config.allowUnfree = true;
        };
      })
    ];

    # `nix shell`/`nix run` on flake refs like `nixpkgs#foo` or `unstable#foo`
    # instantiate pkgs directly and never see `nixpkgs.config.allowUnfree`, so
    # unfree has to be allowed via this env var instead.
    environment.variables.NIXPKGS_ALLOW_UNFREE = "1";

    # Pins the "nixpkgs" registry entry to this flake's stable input (so ad-hoc
    # `nix shell nixpkgs#foo` matches the system) and adds an "unstable" entry
    # so `nix shell unstable#foo` / `nix run unstable#foo` work anywhere.
    nix.registry.nixpkgs.flake = inputs.nixpkgs;
    nix.registry.unstable.flake = inputs.nixpkgs-unstable;
  };
}
