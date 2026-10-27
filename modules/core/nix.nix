# Nix settings, written to /etc/nix/nix.conf, so they apply to every user.
{
  flake.modules.nixos.nix = {
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "configurable-impure-env"
      ];
      impure-env = [ "NIX_CURL_FLAGS" ];
      trusted-users = [
        "root"
        "@wheel"
      ];
    };
  };
}
