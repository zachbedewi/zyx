{
  inputs',
  config,
  lib,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) bool enum package;

  cfg = config.modules.user;
in {
  options.modules.user = {
    desktop = mkOption {
      type = enum ["none" "Hyprland"];
      default = "none";
      description = ''
        The desktop environment/window manager to be used.
      '';
    };

    desktops = {
      hyprland = {
        enable = mkOption {
	  type = bool;
	  default = cfg.desktop == "Hyprland";
	  description = ''
	    Set to true to enable the Hyprland window manager.
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
