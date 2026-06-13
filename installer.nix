{
  config,
  pkgs,
  lib,
  modulesPath,
  self,
  installSystem,
  ...
}:
let
  # can't use pkgs.nixos because we're setting nixpkgs config settings
  # (at least allowUnfree) in install config.
  evaluatedSystem = import (pkgs.path + "/nixos/lib/eval-config.nix") installSystem;
in
{

  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];
  config = {
    # Use a faster squashfs for builds, benefit is marginal for the builds that are much slower
    isoImage.squashfsCompression = "gzip -Xcompression-level 1";
    image.fileName = lib.mkForce "cloudNixos-installer-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
    services.getty.helpLine = ''
      Installer Go brrrrr
    '';

    nixpkgs.config.allowUnfree = true;
    hardware.enableAllFirmware = true;

    services.journald.console = "/dev/tty1";

    nix.settings.substituters = lib.mkForce [ ];

    systemd.services.install = {
      description = "Bootstrap a NixOS installation";
      wantedBy = [ "multi-user.target" ];
      after = [ "polkit.service" ];
      path = [ "/run/current-system/sw/" ];
      script = with pkgs; ''
        # this is just for debugging purposes, can be removed when it all works
        echo 'journalctl -fb -n100 -uinstall' >> ~nixos/.bash_history

        set -euxo pipefail

        wait-for() {
          for _ in seq 10; do
            if $@; then
              break
            fi
            sleep 1
          done
        }


        # add parameters so that nix does not try to contact a cache as we expect
        # to be offline anyway
        ${config.system.build.nixos-install}/bin/nixos-install \
          --system ${evaluatedSystem.config.system.build.toplevel} \
          --no-root-passwd \
          --cores 0

      '';
      environment = config.nix.envVars // {
        inherit (config.environment.sessionVariables) NIX_PATH;
        HOME = "/root";
      };
      serviceConfig = {
        Type = "oneshot";
      };
    };
  };
}

