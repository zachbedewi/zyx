{lib, config, pkgs, inputs, ...}: let
  inherit (lib) mkIf mkOption types;
  
  cfg = config.modules.services.display;
  hyprlandCfg = config.modules.services.display.hyprland;
in {
  options.modules.services.display.hyprland = {
    package = mkOption {
      type = types.package;
      default = inputs.hyprland.packages.${pkgs.system}.hyprland;
      description = "The Hyprland package to use system-wide.";
    };
  };

  config = mkIf (cfg.enable && cfg.backend == "wayland" && cfg.desktopEnvironment == "hyprland") {
    assertions = [
      {
        assertion = config.modules.device.hasWayland;
        message = "Hyprland requires Wayland capability to be enabled.";
      }
      {
        assertion = config.modules.device.supportsCompositing;
        message = "Hyprland requires compositing capability to be enabled.";
      }
    ];

    # Enable Hyprland
    programs.hyprland = {
      enable = true;
      package = hyprlandCfg.package;
      xwayland.enable = true;
    };

    # Enable required services for Wayland
    services.dbus.enable = true;
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };

    # Environment variables for Hyprland
    environment.sessionVariables = {
      WLR_NO_HARDWARE_CURSORS = "1";
      NIXOS_OZONE_WL = "1";
    };

    # Essential system packages for Wayland/Hyprland
    environment.systemPackages = with pkgs; [
      wl-clipboard    # Clipboard utilities (system-wide)
      grim            # Screenshot utility (system-wide)
      slurp           # Screen area selection (system-wide)
    ];
  };
}