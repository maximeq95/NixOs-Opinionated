# Discovers the modules of a directory: every `<name>.nix` file or `<name>/`
# directory (with a default.nix) is an entry named `<name>`.
{ lib }:
dir:
let
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
