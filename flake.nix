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

      roles = import ./lib/roles.nix { inherit lib; };

      # The `key` lets the module system deduplicate a module imported both
      # directly and through `default`.
      mkModule = name: module: {
        key = "nixos-opinionated#${name}";
        _file = "${self.outPath}/flake.nix#${name}";
        imports = [ module ];
      };
    in
    {
      lib = { inherit roles; };

      homeModules.default = mkModule "homeModules.default" (
        import ./modules/home { inherit inputs roles; }
      );

      nixosModules = {
        common = mkModule "nixosModules.common" ./modules/nixos/common.nix;
        system = mkModule "nixosModules.system" {
          imports = [
            self.nixosModules.common
            ./modules/nixos/system.nix
          ];
        };
        wsl = mkModule "nixosModules.wsl" {
          imports = [
            inputs.nixos-wsl.nixosModules.default
            ./modules/nixos/wsl.nix
          ];
        };
        home = mkModule "nixosModules.home" {
          imports = [
            self.nixosModules.common
            inputs.home-manager.nixosModules.home-manager
            (import ./modules/nixos/home.nix {
              inherit roles;
              homeModule = self.homeModules.default;
            })
          ];
        };
        default = mkModule "nixosModules.default" {
          imports = with self.nixosModules; [
            system
            wsl
            home
          ];
        };
      };

      templates = {
        wsl = {
          path = ./templates/wsl;
          description = "NixOS-WSL host consuming nixos-opinionated";
        };
        default = self.templates.wsl;
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      checks = forAllSystems (system: import ./checks.nix { inherit self inputs system; });
    };
}
