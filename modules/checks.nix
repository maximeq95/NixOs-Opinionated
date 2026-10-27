# Helpers for the evaluation checks the features declare, and the check of
# the core alone. A configuration is checked by computing its system
# derivation path: nothing is built, so the checks stay fast enough for CI.
{ config, inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
in
{
  perSystem =
    {
      pkgs,
      system,
      checkLib,
      ...
    }:
    {
      _module.args.checkLib = {
        nixosSystem =
          modules:
          lib.nixosSystem {
            modules = [
              {
                nixpkgs.hostPlatform = system;
                system.stateVersion = "26.05";
              }
            ]
            ++ modules;
          };

        evalCheck =
          name: nixos:
          pkgs.writeText "eval-${name}" (
            builtins.unsafeDiscardStringContext nixos.config.system.build.toplevel.drvPath
          );

        assertCheck =
          name: assertion: message:
          assert lib.assertMsg assertion message;
          pkgs.writeText name "ok";
      };

      # Core only, without any platform: a plain host with a base-only user.
      checks.core-only = checkLib.evalCheck "core-only" (
        checkLib.nixosSystem [
          config.flake.nixosModules.core
          {
            boot.loader.grub.enable = false;
            fileSystems."/" = {
              device = "/dev/null";
              fsType = "ext4";
            };
            users.users.bob.isNormalUser = true;
            opinionated.users.bob = { };
          }
        ]
      );
    };
}
