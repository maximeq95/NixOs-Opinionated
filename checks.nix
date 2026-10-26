# Evaluation checks: each configuration below must evaluate to a system
# derivation. Only the derivation path is computed, nothing is built, so the
# checks stay fast enough for CI.
{
  self,
  inputs,
  system,
}:
let
  inherit (inputs.nixpkgs) lib;
  pkgs = inputs.nixpkgs.legacyPackages.${system};

  mkSystem =
    modules:
    lib.nixosSystem {
      inherit system;
      modules = [
        self.nixosModules.default
        { system.stateVersion = "26.05"; }
      ]
      ++ modules;
    };

  evalCheck =
    name: nixos:
    pkgs.writeText "eval-${name}" (
      builtins.unsafeDiscardStringContext nixos.config.system.build.toplevel.drvPath
    );

  configurations = {
    # Every discovered role, with every optional feature enabled.
    wsl-all-roles = mkSystem [
      {
        opinionated = {
          system.enable = true;
          wsl.enable = true;
          users.alice = {
            roles = self.lib.roles.names;
            git = {
              userName = "Alice";
              userEmail = "alice@example.com";
            };
          };
        };
        home-manager.users.alice.opinionated.roles.ops.azure.enable = true;
      }
    ];

    # Non-WSL host with a base-only user and no system defaults.
    base-only = mkSystem [
      {
        boot.loader.grub.enable = false;
        fileSystems."/" = {
          device = "/dev/null";
          fsType = "ext4";
        };
        users.users.bob.isNormalUser = true;
        opinionated.users.bob = { };
      }
    ];
  };
in
lib.mapAttrs evalCheck configurations
// {
  formatting = pkgs.runCommand "check-formatting" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
    cd ${self}
    find . -name '*.nix' -exec nixfmt --check {} +
    touch $out
  '';

  wsl-default-user =
    let
      defaultUserOf =
        users:
        (mkSystem [
          {
            opinionated = {
              wsl.enable = true;
              inherit users;
            };
          }
        ]).config.wsl.defaultUser;
      single = defaultUserOf { alice = { }; };
      several = defaultUserOf {
        alice = { };
        bob = { };
      };
    in
    assert lib.assertMsg (
      single == "alice"
    ) "single user should be the WSL default user, got ${single}";
    assert lib.assertMsg (
      several == "nixos"
    ) "several users should keep the NixOS-WSL default, got ${several}";
    pkgs.writeText "wsl-default-user" "ok";
}
