# Base role: Neovim with LazyVim as the editor.
{ inputs, ... }:
{
  flake.modules.homeManager.roles =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      # Declares `programs.lazyvim`, which other roles extend as well.
      imports = [ inputs.lazyvim.homeManagerModules.default ];

      config = lib.mkIf config.opinionated.roles.base.enable {
        home.sessionVariables.EDITOR = "nvim";

        # LazyVim, wired through Nix: plugins are injected as pinned `dev` specs
        # pointing at store paths, treesitter parsers are prebuilt, and Mason is
        # disabled (its prebuilt binaries cannot run outside an FHS environment).
        # Consequences: `~/.config/nvim` is read-only and `:Lazy update` does
        # nothing; plugins move when `lazyvim` is updated in flake.lock.
        # Other roles add their own extras and extraPackages.
        programs.lazyvim = {
          enable = true;

          # LSP servers, formatters and linters that LazyVim would otherwise expect
          # Mason to provide. They land on neovim's wrapper PATH, not in the profile.
          extraPackages = with pkgs; [
            nil
            yaml-language-server
            lua-language-server
            stylua
          ];

          extras.lang = {
            nix.enable = true;
            json = {
              enable = true;
              installDependencies = true;
            };
            yaml.enable = true;
            markdown = {
              enable = true;
              installDependencies = true;
              installRuntimeDependencies = true;
            };
          };
        };

        programs.neovim = {
          viAlias = true;
          vimAlias = true;
        };
      };
    };
}
