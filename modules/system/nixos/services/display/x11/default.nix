{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.modules.services.display;
in
{
  imports = [
    ./plasma.nix
  ];

  config = mkIf (cfg.enable && cfg.backend == "x11") {
    # X11-specific configuration can go here
  };
}
