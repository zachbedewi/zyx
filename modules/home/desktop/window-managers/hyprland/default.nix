{
  config,
  lib,
  pkgs,
  desktopConfig,
  ...
}:
let
  session = if desktopConfig != null then desktopConfig.session or null else null;
  isHyprland = session == "hyprland";
in
{
  config = lib.mkIf isHyprland {
    wayland.windowManager.hyprland = {
      enable = true;

      settings = {
        # Monitor configuration - can be customized per user
        monitor = [ ",preferred,auto,1" ];

        # General settings
        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
          layout = "dwindle";
        };

        # Input settings
        input = {
          kb_layout = "us";
          follow_mouse = 1;
          sensitivity = 0;
        };

        # Decoration settings
        decoration = {
          rounding = 10;
          blur = {
            enabled = true;
            size = 3;
            passes = 1;
          };
          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
          };
        };

        # Animation settings
        animations = {
          enabled = true;
          bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
          animation = [
            "windows, 1, 7, myBezier"
            "windowsOut, 1, 7, default, popin 80%"
            "border, 1, 10, default"
            "fade, 1, 7, default"
            "workspaces, 1, 6, default"
          ];
        };

        # Layout settings
        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        # Key bindings
        "$mod" = "SUPER";

        bind = [
          "$mod, Return, exec, kitty"
          "$mod, Q, killactive"
          "$mod, M, exit"
          "$mod, E, exec, thunar"
          "$mod, V, togglefloating"
          "$mod, D, exec, wofi --show drun"
          "$mod, P, pseudo"
          "$mod, J, togglesplit"

          # Move focus
          "$mod, left, movefocus, l"
          "$mod, right, movefocus, r"
          "$mod, up, movefocus, u"
          "$mod, down, movefocus, d"

          # Switch workspaces
          "$mod, 1, workspace, 1"
          "$mod, 2, workspace, 2"
          "$mod, 3, workspace, 3"
          "$mod, 4, workspace, 4"
          "$mod, 5, workspace, 5"
          "$mod, 6, workspace, 6"
          "$mod, 7, workspace, 7"
          "$mod, 8, workspace, 8"
          "$mod, 9, workspace, 9"
          "$mod, 0, workspace, 10"

          # Move window to workspace
          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"
          "$mod SHIFT, 6, movetoworkspace, 6"
          "$mod SHIFT, 7, movetoworkspace, 7"
          "$mod SHIFT, 8, movetoworkspace, 8"
          "$mod SHIFT, 9, movetoworkspace, 9"
          "$mod SHIFT, 0, movetoworkspace, 10"

          # Scroll through workspaces
          "$mod, mouse_down, workspace, e+1"
          "$mod, mouse_up, workspace, e-1"
        ];

        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];
      };
    };

    # Hyprland-specific packages
    home.packages = with pkgs; [
      thunar # File manager
      wofi # Application launcher
      waybar # Status bar
      dunst # Notification daemon
      grim # Screenshot utility
      slurp # Screen region selector
      swappy # Screenshot annotation
    ];
  };
}
