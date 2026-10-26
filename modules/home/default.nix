# Home Manager entry point: shared options plus every discovered role.
{ inputs, roles }:
{ lib, ... }:
{
  imports = [ inputs.lazyvim.homeManagerModules.default ] ++ builtins.attrValues roles.modules;

  options.opinionated.unfreePackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = ''
      Unfree packages (by `lib.getName`) needed by the enabled roles. On NixOS
      they are collected into the system-level `opinionated.unfreePackages`.
    '';
  };

  config._module.args.opinionatedInputs = inputs;
}
