# NixOS-WSL defaults. Requires the NixOS-WSL module (imported by the flake).
{ config, lib, ... }:
let
  cfg = config.opinionated.wsl;
  # Declared by the home module; absent when only the WSL module is imported.
  users = builtins.attrNames (config.opinionated.users or { });
in
{
  options.opinionated.wsl = {
    enable = lib.mkEnableOption "opinionated NixOS-WSL defaults";
  };

  config = lib.mkIf cfg.enable {
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
