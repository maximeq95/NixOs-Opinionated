# NixOs-opinionated

Opinionated, modular NixOS + Home Manager configuration. Import the module of
your **platform** (currently `wsl`), and give each user a list of **roles**.

Every value is a default: anything can be overridden from your own
configuration (use `lib.mkForce` for values set at normal priority).

## Modules

A host imports exactly one platform module; there is no default one.
Importing two platform modules is an evaluation error.

| Output | Provides |
| :--- | :--- |
| `nixosModules.wsl` | The core, plus NixOS-WSL (module included), Windows `$PATH` kept out, Windows GPU driver, `wsl.defaultUser` set to the only user of `opinionated.users` when exactly one is declared. |
| `nixosModules.core` | Platform-agnostic part, included in every platform module; import it alone for a host not covered by a platform. |
| `homeModules.roles` | The roles, for standalone Home Manager use (`opinionated.roles.<role>.enable`); needs `overlays.default` applied to its `pkgs`. |
| `overlays.default` | The packages of this flake (see [Packages](#packages)); applied by the core. |

The core provides:

- **system defaults** (`opinionated.system.enable`, on by default): flakes +
  `nix-command`, `configurable-impure-env` (`NIX_CURL_FLAGS`), `root`/`@wheel`
  trusted users, `nh` with weekly `nh clean` (keeps 14 days) and store
  optimisation, JetBrains Mono Nerd Font, `Europe/Paris` time zone;
- **Home Manager** (module included, `useGlobalPkgs`, `useUserPackages`) for
  the users of `opinionated.users`, with their roles, zsh as login shell for
  `base` users and unfree packages allowed per role.

> The modules already import NixOS-WSL and Home Manager: do not import them a
> second time.

### Adding a platform

Create `modules/platforms/<name>.nix` (any file under `modules/` works, see
[Development](#development)). It registers the platform and contributes its
NixOS settings to `flake.modules.nixos.<name>`, exposed as
`nixosModules.<name>` with the core included and `opinionated.platform` set:

```nix
{
  opinionated.platforms.bare = { };

  flake.modules.nixos.bare =
    { config, lib, ... }:
    {
      users.users = lib.mapAttrs (_: _: {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
      }) config.opinionated.users;
    };
}
```

`nix flake check` evaluates every platform with every role enabled; settings a
platform needs only for that test go in `opinionated.platforms.<name>.checkModule`.
Add a matching `templates/<name>` directory to get a `nix flake init` template.

### Options

| Option | Default | Description |
| :--- | :--- | :--- |
| `opinionated.platform` | set by the platform module | Read-only platform of the host. |
| `opinionated.system.enable` | `true` | System defaults. |
| `opinionated.system.flakePath` | `"/etc/nixos"` | Flake used by `nh os switch` without arguments. |
| `opinionated.system.clean.{enable,dates,keepSince}` | `true`, `"weekly"`, `"14d"` | Store cleanup schedule. |
| `opinionated.users.<name>.roles` | `[ "base" ]` | Roles of the user. |
| `opinionated.users.<name>.git.{userName,userEmail}` | `null` | Git identity. |
| `opinionated.users.<name>.homeDirectory` | `/home/<name>` | Home directory. |
| `opinionated.unfreePackages` | roles' needs | Allowed unfree package names; add yours here. |
| `opinionated.manageUnfreePackages` | `true` | Set to `false` to provide your own `allowUnfreePredicate`. |

## Roles

| Role | Content | Options (`home-manager.users.<name>.opinionated.roles.<role>`) |
| :--- | :--- | :--- |
| `base` | zsh (oh-my-zsh, autosuggestions, syntax highlighting), Starship (Catppuccin Mocha), Zellij, git + delta, direnv + nix-direnv, eza, zoxide, fzf, bat, ripgrep, fd, jq, keychain, LazyVim (nix, json, yaml, markdown) | `git.{userName,userEmail}` |
| `ops` | kubectl, Helm, Flux, oh-my-zsh kubectl/kubectx/helm/terraform/ansible plugins, LazyVim terraform extra | `azure.enable` (default `false`) |
| `dev` | IntelliJ IDEA with plugins, `jdt-language-server` for LazyVim | `intellij.enable`, `intellij.plugins` |
| `llm` | AI CLI of the selected provider; AI plugins in IntelliJ when `dev` is enabled | `provider` (`"github-copilot"`), `intellijPlugins` |

Roles are composable: they append to shared lists (oh-my-zsh plugins, LazyVim
extras and packages, IntelliJ plugins, unfree packages).

### Adding a role

Create `modules/roles/<name>.nix` (or several files, like
`modules/roles/base/`). Registering the role in `opinionated.roles.<name>`
makes it a valid value of `opinionated.users.<user>.roles` and declares the
Home Manager option `opinionated.roles.<name>.enable`; the role contributes
its settings to `flake.modules.homeManager.roles`, guarded by that option:

```nix
{
  opinionated.roles.data.description = "DuckDB, Python";

  flake.modules.homeManager.roles =
    { config, lib, pkgs, ... }:
    {
      config = lib.mkIf config.opinionated.roles.data.enable {
        home.packages = [ pkgs.duckdb ];
        programs.zsh.oh-my-zsh.plugins = [ "python" ];
        opinionated.unfreePackages = [ ];
      };
    };
}
```

A role needing NixOS settings contributes them to `flake.modules.nixos.core`
from the same file (see `modules/roles/base/shell.nix`). Flake inputs are
available as the `inputs` argument of the file (the flake-parts module), not
of the inner modules. `nix flake check` evaluates a system with every role
enabled.

## Packages

The packages of this flake are distributed through `overlays.default`, which
the core applies to the system (and so to Home Manager, through
`useGlobalPkgs`). Modules extend them with `.override` rather than defining
new derivations:

| Package | Overrides |
| :--- | :--- |
| `intellij-idea-with-plugins` | `pluginIds` (JetBrains Marketplace IDs, resolved by [nix-jetbrains-plugins](https://github.com/nix-community/nix-jetbrains-plugins)), `intellij-idea` (e.g. `intellij-idea-oss`) |

A package lives in `pkgs/<name>/package.nix`, written for `callPackage`; the
module adding it (`modules/packages/<name>.nix`) contributes
`overlays.<name>`, which `overlays.default` composes with the others.

## Usage

```bash
nix flake init -t github:pchesneau/NixOs-opinionated#wsl
```

or, by hand:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    opinionated = {
      url = "github:pchesneau/NixOs-opinionated";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, opinionated, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        opinionated.nixosModules.wsl
        {
          system.stateVersion = "26.05";
          opinionated.users.alice = {
            roles = [ "base" "ops" "dev" "llm" ];
            git = { userName = "Alice"; userEmail = "alice@example.com"; };
          };
          home-manager.users.alice.opinionated.roles.ops.azure.enable = true;
        }
      ];
    };
  };
}
```

With `nixosModules.core` alone, the user account itself
(`users.users.<name>.isNormalUser`, …) must be declared by your configuration.

Standalone Home Manager has no system to apply the overlay and allow unfree
packages: give it a `pkgs` that does both.

```nix
homeConfigurations.alice = home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs {
    system = "x86_64-linux";
    overlays = [ opinionated.overlays.default ];
    config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "terraform" ];
  };
  modules = [
    opinionated.homeModules.roles
    {
      home = { username = "alice"; homeDirectory = "/home/alice"; stateVersion = "26.05"; };
      opinionated.roles = { base.enable = true; ops.enable = true; };
    }
  ];
};
```

## LazyVim

Neovim comes from [`pfassina/lazyvim-nix`](https://github.com/pfassina/lazyvim-nix):
plugins and treesitter parsers are resolved by Nix and Mason is disabled.
`~/.config/nvim` is read-only and `:Lazy update` does nothing; plugins move
with the `lazyvim` input. Enable more languages from your configuration:

```nix
home-manager.users.alice.programs.lazyvim.extras.lang.go = {
  enable = true;
  installDependencies = true;
};
```

## Development

The flake follows the [dendritic pattern](https://github.com/mightyiam/dendritic):
every file under `modules/` is a [flake-parts](https://flake.parts) module,
imported by [import-tree](https://github.com/denful/import-tree) (paths
containing `/_` are skipped). A file is a feature, which contributes to
every configuration class it touches, e.g. `modules/roles/base/git.nix`
declares the NixOS `opinionated.users.<name>.git` options and the Home
Manager git settings. File names and locations carry no meaning: move or
split files freely.

| Path | Contents |
| :--- | :--- |
| `modules/flake-parts.nix` | Systems; publishes `flake.modules.{nixos,homeManager}` as `nixosModules`/`homeModules`. |
| `modules/roles.nix`, `modules/platforms.nix` | Role and platform registries (`opinionated.roles`, `opinionated.platforms`). |
| `modules/overlays.nix` | `overlays.default`, applied by the core. |
| `modules/core/` | System defaults, Home Manager integration, unfree packages. |
| `modules/roles/`, `modules/platforms/` | One role or platform per file or directory. |
| `modules/packages/` | One overlay per package of `pkgs/`. |
| `modules/checks.nix`, `modules/formatter.nix`, `modules/templates.nix` | Check helpers (`checkLib`), formatter, templates. |

```bash
nix flake check   # evaluates test systems and checks formatting
nix fmt           # formats every Nix file
```
