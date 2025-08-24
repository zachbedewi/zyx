{
  lib,
  config,
  ...
}:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) enum nullOr;
  inherit (lib) mkIf;

  cfg = config.modules.services.display;
in
{
  options.modules.services.display = {
    enable = mkEnableOption "display services and desktop environment";

    backend = mkOption {
      type = enum [
        "x11"
        "wayland"
      ];
      default = "x11";
      description = "Display server backend to use (X11 or Wayland)";
    };

    desktopEnvironment = mkOption {
      type = nullOr (enum [
        "plasma"
        "hyprland"
      ]);
      default = null;
      description = "Desktop environment to enable. null means no DE will be configured.";
    };
  };

  imports = [
    ./x11
    ./wayland
  ];

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.desktopEnvironment != null -> config.modules.device.hasGUI;
        message = "Desktop environment requires GUI capability to be enabled.";
      }
      {
        assertion = cfg.backend == "wayland" -> config.modules.device.hasWayland;
        message = "Wayland backend requires Wayland capability to be enabled.";
      }
      {
        assertion = cfg.desktopEnvironment == "hyprland" -> cfg.backend == "wayland";
        message = "Hyprland desktop environment requires Wayland backend.";
      }
    ];

    # Enable X11 windowing system when using X11 backend
    services.xserver.enable = mkIf (cfg.backend == "x11") true;
  };
}
