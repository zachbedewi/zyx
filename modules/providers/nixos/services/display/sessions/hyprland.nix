{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.options) mkEnableOption;

  cfg = config.zyx.services.display.sessions.hyprland;
in
{
  options.zyx.services.display.sessions.hyprland = {
    enable = mkEnableOption "Hyprland Wayland compositor session";
  };

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # Enable XDG portal for Hyprland
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    };

    # Common Wayland environment variables
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      XDG_SESSION_TYPE = "wayland";
    };
  };
}
