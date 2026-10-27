# NixOS-WSL platform.
{ inputs }:
{ config, lib, ... }:
let
  users = builtins.attrNames config.opinionated.users;
in
{
  imports = [ inputs.nixos-wsl.nixosModules.default ];

  config = {
    opinionated.platform = "wsl";

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
}
