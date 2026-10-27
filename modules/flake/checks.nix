# Evaluation checks: each configuration below must evaluate. Only derivation
# paths are computed, nothing is built, so the checks stay fast enough for CI.
{ config, inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  inherit (config.flake) overlays;
  inherit (config.flake.modules) nixos homeManager;
  roleNames = builtins.attrNames (removeAttrs homeManager [ "common" ]);
in
{
  perSystem =
    { pkgs, system, ... }:
    let
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
        name: drv: pkgs.writeText "eval-${name}" (builtins.unsafeDiscardStringContext drv.drvPath);

      wslDefaultUserOf =
        users:
        (nixosSystem [
          nixos.wsl
          { roles = { inherit users; }; }
        ]).config.wsl.defaultUser;
    in
    {
      checks = {
        # Every role, every optional feature, and modules imported several
        # times, as consumers may: their keys make it harmless.
        wsl =
          evalCheck "wsl"
            (nixosSystem [
              nixos.wsl
              nixos.core
              config.flake.nixosModules.nh
              {
                roles.users.alice = roleNames;
                home-manager.users.alice = {
                  imports = [ homeManager.dev ];
                  roles.ops.azure.enable = true;
                };
              }
            ]).config.system.build.toplevel;

        # Core only, without any platform: a plain host with a base user.
        core-only =
          evalCheck "core-only"
            (nixosSystem [
              nixos.core
              {
                boot.loader.grub.enable = false;
                fileSystems."/" = {
                  device = "/dev/null";
                  fsType = "ext4";
                };
                users.users.bob.isNormalUser = true;
                roles.users.bob = [ "base" ];
              }
            ]).config.system.build.toplevel;

        # Standalone Home Manager, with roles that do not need base or dev.
        home-standalone =
          evalCheck "home-standalone"
            (inputs.home-manager.lib.homeManagerConfiguration {
              pkgs = import inputs.nixpkgs {
                inherit system;
                overlays = [ overlays.default ];
                config.allowUnfree = true;
              };
              modules = [
                homeManager.ops
                homeManager.llm
                {
                  home = {
                    username = "alice";
                    homeDirectory = "/home/alice";
                    stateVersion = "26.05";
                  };
                }
              ];
            }).activationPackage;

        wsl-default-user =
          let
            single = wslDefaultUserOf { alice = [ ]; };
            several = wslDefaultUserOf {
              alice = [ ];
              bob = [ ];
            };
          in
          assert lib.assertMsg (
            single == "alice"
          ) "single user should be the WSL default user, got ${single}";
          assert lib.assertMsg (
            several == "nixos"
          ) "several users should keep the NixOS-WSL default, got ${several}";
          pkgs.writeText "wsl-default-user" "ok";
      };
    };
}
