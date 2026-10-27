{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    import-tree.url = "github:denful/import-tree";

    nixos-roles = {
      url = "github:pchesneau/NixOs-Opinionated";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Every file under ./modules is a flake-parts module.
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
