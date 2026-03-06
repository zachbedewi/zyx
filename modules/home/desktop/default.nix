{
  config,
  lib,
  pkgs,
  desktopConfig,
  ...
}:
let
  session = if desktopConfig != null then desktopConfig.session or null else null;
in
{
  imports = [
    ./environments/kde
    ./window-managers/hyprland
  ];

  config = lib.mkIf (session != null) {
    # Common desktop packages that all sessions benefit from
    home.packages = with pkgs; [
      wl-clipboard # Wayland clipboard utilities
      xdg-utils # XDG utilities like xdg-open
    ];
  };
}
