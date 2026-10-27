# `nix flake init -t` templates.
{
  flake.templates = {
    wsl = {
      path = ../../templates/wsl;
      description = "NixOS-WSL host with users and their roles";
    };
    dendritic = {
      path = ../../templates/dendritic;
      description = "NixOS-WSL host with users and their roles, in a dendritic flake";
    };
  };
}
