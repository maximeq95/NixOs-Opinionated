{
  description = "Opinionated, modular NixOS and Home Manager configuration with composable user roles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-jetbrains-plugins = {
      url = "github:nix-community/nix-jetbrains-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager module exposing `programs.lazyvim`. It patches the upstream
    # LazyVim starter config so every plugin, treesitter parser and LSP binary
    # is resolved through Nix instead of being downloaded at runtime.
    lazyvim = {
      url = "github:pfassina/lazyvim-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      inherit (nixpkgs) lib;
      systems = [ "x86_64-linux" ];
      forAllSystems = lib.genAttrs systems;

      discover = import ./lib/discover.nix { inherit lib; };
      roles = discover ./modules/home/roles;
      platforms = discover ./modules/nixos/platforms;

      # The `key` lets the module system deduplicate a module imported several
      # times, e.g. the core shared by every platform module.
      mkModule = name: module: {
        key = "nixos-opinionated#${name}";
        _file = "${self.outPath}/flake.nix#${name}";
        imports = [ module ];
      };
    in
    {
      lib = { inherit roles platforms; };

      homeModules.roles = mkModule "homeModules.roles" (import ./modules/home { inherit inputs roles; });

      # One module per platform, each including the core. There is
      # deliberately no `default`: a host has to pick its platform.
      nixosModules = {
        core = mkModule "nixosModules.core" (
          import ./modules/nixos/core {
            inherit inputs roles platforms;
            homeModule = self.homeModules.roles;
          }
        );
      }
      // lib.mapAttrs (
        name: path:
        mkModule "nixosModules.${name}" {
          imports = [
            self.nixosModules.core
            (import path { inherit inputs; })
          ];
        }
      ) platforms.modules;

      templates = lib.mapAttrs (name: _: {
        path = ./templates/${name};
        description = "NixOS host on the `${name}` platform consuming nixos-opinionated";
      }) (builtins.readDir ./templates);

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      checks = forAllSystems (system: import ./checks.nix { inherit self inputs system; });
    };
}
