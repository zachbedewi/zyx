{lib, config, ...}: let
  inherit (lib) mkIf;
  cfg = config.modules.services.display;
in {
  imports = [
    ./hyprland
  ];

  config = mkIf (cfg.enable && cfg.backend == "wayland") {
    # Wayland-specific configuration can go here
  };
}