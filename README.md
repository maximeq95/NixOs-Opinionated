# NixOs-Opinionated

NixOS + Home Manager modules for development machines. Import the module of
your **platform** (currently `wsl`) and give each user **roles**: sets of
tools and settings that compose (shell, ops, dev, AI tooling).

Every module is published under `modules.<class>.<name>`, the output
[dendritic](https://github.com/mightyiam/dendritic) flakes consume, and
under the classic `nixosModules` / `homeModules`. Importing a module enables
it, and every value is a default on the upstream NixOS and Home Manager
options: override them where you would anyway (`lib.mkForce` for values set
at normal priority).

## Quick start

```bash
# A dendritic flake (flake-parts + import-tree):
nix flake init -t github:pchesneau/NixOs-Opinionated#dendritic
# A classic flake:
nix flake init -t github:pchesneau/NixOs-Opinionated#wsl
```

There are two places to configure a user, and one rule:

- **`roles.users.<name>`** (NixOS) lists the roles of the user;
- **`home-manager.users.<name>`** holds everything else about that user: the
  options of their roles (`roles.<role>.*`) and any Home Manager setting.

## Usage

### From a dendritic flake

The host is one of your `flake.modules.nixos.*` modules, which imports a
platform module of this flake:

```nix
# modules/hosts/workstation.nix
{ config, inputs, ... }:
{
  flake.modules.nixos.workstation = {
    imports = [ inputs.nixos-roles.modules.nixos.wsl ];

    system.stateVersion = "26.05";
    roles.users.alice = [ "base" "ops" "dev" ];
    home-manager.users.alice.imports = [ config.flake.modules.homeManager.alice ];
  };

  flake.nixosConfigurations.workstation = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      config.flake.modules.nixos.workstation
      { nixpkgs.hostPlatform = "x86_64-linux"; }
    ];
  };
}
```

```nix
# modules/users/alice.nix
{
  flake.modules.homeManager.alice = {
    programs.git.settings.user = { name = "Alice"; email = "alice@example.com"; };
    roles.ops.azure.enable = true;
  };
}
```

A role is an ordinary Home Manager module: `roles.users` imports it for you,
and you can also import it yourself
(`imports = [ inputs.nixos-roles.modules.homeManager.llm ]`).

### From a classic flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-roles = {
      url = "github:pchesneau/NixOs-Opinionated";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixos-roles, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nixos-roles.nixosModules.wsl
        {
          system.stateVersion = "26.05";
          roles.users.alice = [ "base" "ops" "dev" "llm" ];
          home-manager.users.alice = {
            programs.git.settings.user = { name = "Alice"; email = "alice@example.com"; };
            roles.ops.azure.enable = true;
          };
        }
      ];
    };
  };
}
```

### Standalone Home Manager

Without NixOS, nothing applies the overlay or allows unfree packages: give
Home Manager a `pkgs` that does both, and import the roles.

```nix
homeConfigurations.alice = home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs {
    system = "x86_64-linux";
    overlays = [ nixos-roles.overlays.default ];
    config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "terraform" ];
  };
  modules = with nixos-roles.modules.homeManager; [
    base
    ops
    {
      home = { username = "alice"; homeDirectory = "/home/alice"; stateVersion = "26.05"; };
    }
  ];
};
```

### Picking features

Every module can be imported on its own, e.g. `modules.nixos.nh` for the
store cleanup only. A module imported several times (directly and through a
platform module, say) is imported once: every published module has a `key`.

## Roles

| Role | Content | Options (`home-manager.users.<name>.roles.<role>`) |
| :--- | :--- | :--- |
| `base` | zsh (oh-my-zsh, autosuggestions, syntax highlighting) as login shell, Starship (Catppuccin Mocha), Zellij, git + delta, direnv + nix-direnv, eza, zoxide, fzf, bat, ripgrep, fd, jq, keychain, LazyVim (nix, json, yaml, markdown) | none; the git identity goes in `programs.git.settings.user` |
| `ops` | kubectl, Helm, Flux, oh-my-zsh kubectl/kubectx/helm/terraform/ansible plugins, LazyVim terraform extra | `azure.enable` (default `false`) |
| `dev` | IntelliJ IDEA with plugins, `jdt-language-server` for LazyVim | `intellij.enable`, `intellij.plugins` |
| `llm` | AI CLI of the selected provider; AI plugins in IntelliJ when `dev` is imported too | `provider` (`"github-copilot"`), `intellijPlugins` |

Roles compose: they append to shared lists (oh-my-zsh plugins, LazyVim
extras and packages, IntelliJ plugins, unfree packages). zsh becomes the
login shell of the users given `base` through `roles.users`.

## Modules

| `modules.nixos.*` | Provides |
| :--- | :--- |
| `wsl` | `core`, plus NixOS-WSL: Windows `$PATH` kept out, Windows GPU driver, `wsl.defaultUser` set to the only user of `roles.users` when there is exactly one. |
| `core` | `nix`, `nh`, `fonts`, `time-zone` and `roles`: import it alone for a host not covered by a platform (the user accounts are then yours to declare). |
| `nix` | Flakes + `nix-command`, `configurable-impure-env` (`NIX_CURL_FLAGS`), `root`/`@wheel` trusted users. |
| `nh` | `programs.nh` with `flake = "/etc/nixos"` and a weekly `nh clean` keeping 14 days, plus store optimisation on the same schedule. |
| `fonts` | JetBrains Mono Nerd Font. |
| `time-zone` | `Europe/Paris`. |
| `roles` | Home Manager (`useGlobalPkgs`, `useUserPackages`) for the users of `roles.users`, with their roles, the overlay and their unfree packages. |
| `unfree` | `roles.unfreePackages`, the allow list of unfree packages. |

| `modules.homeManager.*` | Provides |
| :--- | :--- |
| `base`, `ops`, `dev`, `llm` | The [roles](#roles). |
| `common` | What the roles share; every role imports it. |

`overlays.default` holds the packages of this flake (see
[Packages](#packages)); the `roles` module applies it.

### Options

| Option | Default | Description |
| :--- | :--- | :--- |
| `roles.users.<name>` | — | Roles of the user, who gets a Home Manager configuration. |
| `roles.unfreePackages` | roles' needs | Allowed unfree package names; add yours here. |
| `roles.manageUnfreePackages` | `true` | Set to `false` to provide your own `nixpkgs.config.allowUnfreePredicate`. |

## LazyVim

Neovim comes from [`pfassina/lazyvim-nix`](https://github.com/pfassina/lazyvim-nix):
Nix resolves the plugins and treesitter parsers, and Mason is disabled.
`~/.config/nvim` is read-only and `:Lazy update` does nothing; plugins move
with the `lazyvim` input. Enable more languages from your configuration:

```nix
home-manager.users.alice.programs.lazyvim.extras.lang.go = {
  enable = true;
  installDependencies = true;
};
```

## Packages

The packages of this flake are distributed through `overlays.default`.
Modules extend them with `.override`:

| Package | Overrides |
| :--- | :--- |
| `intellij-idea-with-plugins` | `pluginIds` (JetBrains Marketplace IDs, resolved by [nix-jetbrains-plugins](https://github.com/nix-community/nix-jetbrains-plugins)), `intellij-idea` (e.g. `intellij-idea-oss`) |

## Development

The flake is dendritic: every file under `modules/` is a
[flake-parts](https://flake.parts) module, imported by
[import-tree](https://github.com/denful/import-tree) (paths containing `/_`
are skipped). A file holds one feature and contributes to every module it
touches; several files may contribute to the same module.

Each file has two levels, which is what takes getting used to:

```nix
# modules/roles/ops.nix
{ config, ... }:                                 # flake level: `config.flake.*`
let
  inherit (config.flake.modules) homeManager;
in
{
  flake.modules.homeManager.ops =                # stored, evaluated later
    { config, lib, pkgs, ... }:                  # Home Manager level
    {
      imports = [ homeManager.common ];
      home.packages = [ pkgs.kubectl ];
    };
}
```

The outer function is evaluated with the flake; the inner one is an ordinary
Home Manager module, kept as a value (a `deferredModule`) until a
configuration imports it. Its `config` is the user's Home Manager
configuration, not the flake's.

| Path | Contents |
| :--- | :--- |
| `modules/flake/` | Flake plumbing: published modules (`flake-parts.nix`), overlays, formatter, templates, checks. |
| `modules/core/` | The `core` module and the NixOS features it imports. |
| `modules/platforms/` | One platform module per file, including `core`. |
| `modules/roles/` | `roles.users` (`users.nix`), unfree packages, and one role per file or directory. |
| `modules/packages/` | One package per directory: `_package.nix` for `callPackage`, `default.nix` adds it to the overlays. |
| `templates/` | `nix flake init` templates. |

```bash
nix flake check   # evaluates test configurations and checks formatting
nix fmt           # formats every Nix file
```

To inspect what a module is made of, from a `nix repl`:

```
:lf .
:p outputs.modules.homeManager.base
```

### Adding a role

Create `modules/roles/<name>.nix` (or a directory). Contributing to
`flake.modules.homeManager.<name>` makes it a role, and a valid value of
`roles.users.<user>`:

```nix
{ config, ... }:
let
  inherit (config.flake.modules) homeManager;
in
{
  flake.modules.homeManager.data =
    { pkgs, ... }:
    {
      imports = [ homeManager.common ];
      home.packages = [ pkgs.duckdb ];
      programs.zsh.oh-my-zsh.plugins = [ "python" ];
      roles.unfreePackages = [ ];
    };
}
```

Options of the role go under `roles.<name>`. A role needing NixOS settings
contributes them to `flake.modules.nixos.roles` from the same file (see
`modules/roles/base/shell.nix`).

### Adding a platform

Create `modules/platforms/<name>.nix`, contributing to
`flake.modules.nixos.<name>` a module that imports `core`:

```nix
{ config, ... }:
let
  inherit (config.flake.modules) nixos;
in
{
  flake.modules.nixos.bare =
    { config, lib, ... }:
    {
      imports = [ nixos.core ];
      users.users = lib.mapAttrs (_: _: {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
      }) config.roles.users;
    };
}
```

Then add a configuration to `modules/flake/checks.nix` and, optionally, a
template.
