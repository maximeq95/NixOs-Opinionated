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
      modules = [ { system.stateVersion = "26.05"; } ] ++ modules;
    };

  evalCheck =
    name: nixos:
    pkgs.writeText "eval-${name}" (
      builtins.unsafeDiscardStringContext nixos.config.system.build.toplevel.drvPath
    );

  # Settings a platform needs to evaluate in a test, beyond its own defaults.
  platformFixtures = { };

  # Every discovered role, with every optional feature enabled.
  allRolesUser = {
    opinionated.users.alice = {
      roles = self.lib.roles.names;
      git = {
        userName = "Alice";
        userEmail = "alice@example.com";
      };
    };
    home-manager.users.alice.opinionated.roles.ops.azure.enable = true;
  };

  platformConfigurations = lib.mapAttrs' (
    name: _:
    let
      nixos = mkSystem [
        self.nixosModules.${name}
        # Imported again, as a host importing the core explicitly would.
        self.nixosModules.core
        (platformFixtures.${name} or { })
        allRolesUser
      ];
    in
    lib.nameValuePair "platform-${name}" (
      assert lib.assertMsg (
        nixos.config.opinionated.platform == name
      ) "nixosModules.${name} should set opinionated.platform to ${name}";
      nixos
    )
  ) self.lib.platforms.modules;

  configurations = platformConfigurations // {
    # Core only, without any platform: a plain host with a base-only user.
    core-only = mkSystem [
      self.nixosModules.core
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

  wslDefaultUserOf =
    users:
    (mkSystem [
      self.nixosModules.wsl
      { opinionated = { inherit users; }; }
    ]).config.wsl.defaultUser;

  # Stands for a second platform module: it sets the platform again.
  conflictingPlatforms = mkSystem [
    self.nixosModules.wsl
    { opinionated.platform = "wsl"; }
  ];
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
      single = wslDefaultUserOf { alice = { }; };
      several = wslDefaultUserOf {
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

  platform-exclusive =
    assert lib.assertMsg (
      !(builtins.tryEval conflictingPlatforms.config.opinionated.platform).success
    ) "setting the platform twice should fail";
    pkgs.writeText "platform-exclusive" "ok";
}
