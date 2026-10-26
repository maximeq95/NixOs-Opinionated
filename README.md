# NixOs-opinionated

Opinionated, modular NixOS + Home Manager configuration, primarily targeting
[NixOS-WSL](https://github.com/nix-community/NixOS-WSL). Import the modules,
flip a few `enable` switches, and give each user a list of **roles**.

Every value is a default: anything can be overridden from your own
configuration (use `lib.mkForce` for values set at normal priority).

## Modules

| Output | Enable with | Provides |
| :--- | :--- | :--- |
| `nixosModules.system` | `opinionated.system.enable` | Flakes + `nix-command`, `configurable-impure-env` (`NIX_CURL_FLAGS`), `root`/`@wheel` trusted users, `nh` with weekly `nh clean` (keeps 14 days) and store optimisation, JetBrains Mono Nerd Font, `Europe/Paris` time zone. |
| `nixosModules.wsl` | `opinionated.wsl.enable` | NixOS-WSL (module included), Windows `$PATH` kept out, Windows GPU driver, `wsl.defaultUser` set to the only user of `opinionated.users` when exactly one is declared. |
| `nixosModules.home` | `opinionated.users.<name>` | Home Manager (module included, `useGlobalPkgs`, `useUserPackages`), the roles, zsh as login shell for `base` users, unfree packages allowed per role. |
| `nixosModules.default` | — | All of the above. |
| `homeModules.default` | `opinionated.roles.<role>.enable` | The roles, for direct use in Home Manager. |

> `nixosModules.wsl` and `nixosModules.home` already import NixOS-WSL and Home
> Manager: do not import them a second time.

### Options

| Option | Default | Description |
| :--- | :--- | :--- |
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

1. Create `modules/home/roles/<name>.nix` (or `<name>/default.nix`). It is
   discovered automatically and becomes a valid value of
   `opinionated.users.<user>.roles`.
2. Declare `options.opinionated.roles.<name>.enable` and guard its config with
   it:

   ```nix
   { config, lib, pkgs, ... }:
   let
     cfg = config.opinionated.roles.data;
   in
   {
     options.opinionated.roles.data.enable = lib.mkEnableOption "the data role";

     config = lib.mkIf cfg.enable {
       home.packages = [ pkgs.duckdb ];
       programs.zsh.oh-my-zsh.plugins = [ "python" ];
       opinionated.unfreePackages = [ ];
     };
   }
   ```

Flake inputs are available to roles as the `opinionatedInputs` module
argument. `nix flake check` evaluates a system with every role enabled.

## Usage

```bash
nix flake init -t github:pchesneau/NixOs-opinionated
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
        opinionated.nixosModules.default
        {
          system.stateVersion = "26.05";
          opinionated = {
            system.enable = true;
            wsl.enable = true;
            users.alice = {
              roles = [ "base" "ops" "dev" "llm" ];
              git = { userName = "Alice"; userEmail = "alice@example.com"; };
            };
          };
          home-manager.users.alice.opinionated.roles.ops.azure.enable = true;
        }
      ];
    };
  };
}
```

On a non-WSL host, the user account itself (`users.users.<name>.isNormalUser`,
…) must be declared by your configuration.

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

```bash
nix flake check   # evaluates test systems and checks formatting
nix fmt           # formats every Nix file
```
