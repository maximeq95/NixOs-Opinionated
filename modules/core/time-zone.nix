{
  flake.modules.nixos.time-zone =
    { lib, ... }:
    {
      time.timeZone = lib.mkDefault "Europe/Paris";
    };
}
