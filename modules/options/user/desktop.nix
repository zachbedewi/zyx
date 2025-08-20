{
  inputs',
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkOption;
  inherit (lib.types)
    bool
    enum
    package
    str
    nullOr
    ;

  cfg = config.modules.user;
in
{
  options.modules.user = {
    primaryUser = mkOption {
      type = str;
      default = "skitzo";
      description = "The primary user account name for auto-login and other user-specific configurations.";
    };

    desktop = mkOption {
      type = enum [
        "none"
        "plasma"
        "hyprland"
      ];
      default = "none";
      description = ''
        The desktop environment/window manager to be used.
        This option is being deprecated in favor of modules.services.display.desktopEnvironment.
      '';
    };

    desktops = {
      hyprland = {
        enable = mkOption {
          type = bool;
          default = cfg.desktop == "hyprland";
          description = ''
            Set to true to enable the Hyprland window manager.
            This option is being deprecated in favor of modules.services.display configuration.
          '';
        };

        package = mkOption {
          type = package;
          default = inputs'.hyprland.packages.hyprland;
          description = ''
            The Hyprland package to use.
          '';
        };
      };
    };
  };
}
