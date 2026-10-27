# Platforms: a platform registers itself in `opinionated.platforms.<name>`
# and contributes its settings to `flake.modules.nixos.<name>`, published as
# `nixosModules.<name>` with the core included. A host imports exactly one
# platform module: the read-only `opinionated.platform` option makes
# importing two of them an evaluation error.
{ config, lib, ... }:
let
  inherit (config.opinionated) platforms;
  inherit (config.flake) nixosModules;

  # Every role, with every optional feature enabled.
  allRolesUser = {
    opinionated.users.alice = {
      roles = lib.attrNames config.opinionated.roles;
      git = {
        userName = "Alice";
        userEmail = "alice@example.com";
      };
    };
    home-manager.users.alice.opinionated.roles.ops.azure.enable = true;
  };
in
{
  options.opinionated.platforms = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.checkModule = lib.mkOption {
          type = lib.types.deferredModule;
          default = { };
          description = "Settings the platform needs to evaluate in `nix flake check`, beyond its own defaults.";
        };
      }
    );
    default = { };
    description = "The platforms, by name.";
  };

  config = lib.mkMerge [
    {
      flake.modules.nixos = lib.mapAttrs (name: _: {
        imports = [ nixosModules.core ];
        opinionated.platform = name;
      }) platforms;
    }
    {
      # Read-only without a default: a default would count as a definition.
      flake.modules.nixos.core.options.opinionated.platform = lib.mkOption {
        type = lib.types.enum (lib.attrNames platforms);
        readOnly = true;
        description = ''
          Platform of this host, set by the imported platform module
          (`nixosModules.<platform>`) and undefined when only the core is
          imported. Being read-only, it makes importing two platform modules an
          evaluation error.
        '';
      };

      perSystem =
        { checkLib, ... }:
        {
          checks =
            lib.mapAttrs' (
              name: platform:
              let
                nixos = checkLib.nixosSystem [
                  nixosModules.${name}
                  # Imported again, as a host importing the core explicitly would.
                  nixosModules.core
                  platform.checkModule
                  allRolesUser
                ];
              in
              lib.nameValuePair "platform-${name}" (
                assert lib.assertMsg (
                  nixos.config.opinionated.platform == name
                ) "nixosModules.${name} should set opinionated.platform to ${name}";
                checkLib.evalCheck name nixos
              )
            ) platforms
            // {
              # Stands for a second platform module: it sets the platform again.
              platform-exclusive = checkLib.assertCheck "platform-exclusive" (lib.all (
                name:
                let
                  nixos = checkLib.nixosSystem [
                    nixosModules.${name}
                    { opinionated.platform = name; }
                  ];
                in
                !(builtins.tryEval nixos.config.opinionated.platform).success
              ) (lib.attrNames platforms)) "setting the platform twice should fail";
            };
        };
    }
  ];
}
