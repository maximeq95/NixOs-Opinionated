# JetBrains Mono Nerd Font, whose glyphs the Starship prompt uses.
{
  flake.modules.nixos.fonts =
    { pkgs, ... }:
    {
      fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
    };
}
