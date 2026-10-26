# Discovers Home Manager roles from modules/home/roles.
#
# Every `<name>.nix` file or `<name>/` directory (with a default.nix) in that
# folder is a role. A role module must declare `opinionated.roles.<name>`
# with at least an `enable` option.
{ lib }:
let
  dir = ../modules/home/roles;
  entries = lib.filterAttrs (
    name: type: type == "directory" || (type == "regular" && lib.hasSuffix ".nix" name)
  ) (builtins.readDir dir);
in
rec {
  modules = lib.mapAttrs' (
    file: _: lib.nameValuePair (lib.removeSuffix ".nix" file) (dir + "/${file}")
  ) entries;

  names = builtins.attrNames modules;
}
