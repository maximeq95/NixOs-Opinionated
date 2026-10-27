# NixOS-WSL platform: the core, plus NixOS-WSL with defaults.
{ config, inputs, ... }:
let
  inherit (config.flake.modules) nixos;
in
{
  flake.modules.nixos.wsl =
    { config, lib, ... }:
    let
      users = builtins.attrNames config.roles.users;
    in
    {
      imports = [
        nixos.core
        inputs.nixos-wsl.nixosModules.default
      ];

      wsl = {
        enable = true;
        # The only user of `roles.users`, if there is exactly one.
        defaultUser = lib.mkIf (builtins.length users == 1) (lib.mkDefault (builtins.head users));
        # Keeps Windows binaries out of $PATH, so commands always resolve to
        # their Nix-provided version.
        interop.includePath = lib.mkDefault false;
        useWindowsDriver = lib.mkDefault true;
      };
    };
}
