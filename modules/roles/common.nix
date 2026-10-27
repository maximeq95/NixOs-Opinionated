# The module every role imports (once, thanks to its key), for what the roles
# share: the LazyVim module, which several of them extend, and the options
# other files add to it (see unfree.nix).
{ inputs, ... }:
{
  flake.modules.homeManager.common = {
    # Declares `programs.lazyvim`.
    imports = [ inputs.lazyvim.homeManagerModules.default ];
  };
}
