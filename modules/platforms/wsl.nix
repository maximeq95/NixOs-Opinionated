# NixOS-WSL platform.
{ config, inputs, ... }:
let
  inherit (config.flake) nixosModules;
in
{
  opinionated.platforms.wsl = { };

  flake.modules.nixos.wsl =
    { config, lib, ... }:
    let
      users = builtins.attrNames config.opinionated.users;
    in
    {
      imports = [ inputs.nixos-wsl.nixosModules.default ];

      wsl = {
        enable = true;
        # The only user declared in `opinionated.users`, if there is exactly one.
        defaultUser = lib.mkIf (builtins.length users == 1) (lib.mkDefault (builtins.head users));
        # Keeps Windows binaries out of $PATH, so commands always resolve to
        # their Nix-provided version.
        interop.includePath = lib.mkDefault false;
        useWindowsDriver = lib.mkDefault true;
      };
    };

  perSystem =
    { checkLib, ... }:
    let
      defaultUserOf =
        users:
        (checkLib.nixosSystem [
          nixosModules.wsl
          { opinionated = { inherit users; }; }
        ]).config.wsl.defaultUser;

      single = defaultUserOf { alice = { }; };
      several = defaultUserOf {
        alice = { };
        bob = { };
      };
    in
    {
      checks.wsl-default-user =
        checkLib.assertCheck "wsl-default-user" (single == "alice" && several == "nixos")
          "the only user should be the WSL default user (got ${single}), several users should keep the NixOS-WSL default (got ${several})";
    };
}
