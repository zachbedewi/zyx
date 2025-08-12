# Display service abstraction interface
{ lib, config, ... }:

{
  options.services.display = {
    enable = lib.mkOption {
      type = lib.types.bool;
      description = "Enable display services";
      default = config.device.capabilities.hasGUI;
    };

    backend = lib.mkOption {
      type = lib.types.enum [ "x11" "wayland" "quartz" ];
      description = "Display backend to use";
      default = "x11";
    };

    desktopEnvironment = lib.mkOption {
      type = lib.types.enum [ "kde" "gnome" "hyprland" "sway" "i3" "none" ];
      description = "Desktop environment or window manager";
      default = "kde";
    };

    compositing = lib.mkOption {
      type = lib.types.bool;
      description = "Enable desktop compositing";
      default = true;
    };

    # Display hardware features
    multiMonitor = lib.mkOption {
      type = lib.types.bool;
      description = "Enable multi-monitor support";
      default = false;
    };

    highRefreshRate = lib.mkOption {
      type = lib.types.bool;
      description = "Enable high refresh rate display support";
      default = false;
    };

    hidpi = lib.mkOption {
      type = lib.types.bool;
      description = "Enable HiDPI display scaling";
      default = false;
    };

    # Graphics features
    acceleration = lib.mkOption {
      type = lib.types.bool;
      description = "Enable hardware graphics acceleration";
      default = config.device.capabilities.hasGPU;
    };

    driver = lib.mkOption {
      type = lib.types.enum [ "nvidia" "amd" "intel" "nouveau" "auto" ];
      description = "Graphics driver to use";
      default = "auto";
    };

    # Wayland-specific options
    waylandPortals = lib.mkOption {
      type = lib.types.bool;
      description = "Enable Wayland desktop portals";
      default = false;
    };

    screenSharing = lib.mkOption {
      type = lib.types.bool;
      description = "Enable screen sharing capabilities";
      default = false;
    };

    # Gaming and performance
    gaming = lib.mkOption {
      type = lib.types.bool;
      description = "Enable gaming-optimized display settings";
      default = false;
    };

    vrSupport = lib.mkOption {
      type = lib.types.bool;
      description = "Enable VR/AR display support";
      default = false;
    };

    # Internal options for platform-specific implementations
    _implementation = lib.mkOption {
      type = lib.types.attrs;
      description = "Platform-specific display implementation";
      internal = true;
      default = {};
    };
  };

  config = lib.mkIf config.services.display.enable {
    assertions = [
      {
        assertion = config.device.capabilities.hasGUI;
        message = "Display service requires GUI capability";
      }
      {
        assertion = config.services.display.backend != null;
        message = "Display backend must be specified";
      }
      {
        assertion = 
          config.services.display.acceleration -> 
          config.device.capabilities.hasGPU;
        message = "Hardware acceleration requires GPU capability";
      }
      {
        assertion = 
          config.services.display.backend == "wayland" -> 
          config.device.capabilities.hasWayland;
        message = "Wayland backend requires Wayland capability";
      }
      {
        assertion = 
          config.services.display.vrSupport -> 
          (config.services.display.acceleration && config.device.capabilities.hasGPU);
        message = "VR support requires hardware acceleration and GPU";
      }
      {
        assertion = 
          (config.services.display.desktopEnvironment == "hyprland" || 
           config.services.display.desktopEnvironment == "sway") -> 
          config.services.display.backend == "wayland";
        message = "Hyprland and Sway require Wayland backend";
      }
    ];

    # Platform-specific backend defaults
    services.display.backend = lib.mkDefault (
      if config.platform.capabilities.isDarwin then "quartz"
      else if config.device.capabilities.hasWayland then "wayland"
      else "x11"
    );

    # Set intelligent defaults based on device capabilities
    services.display.acceleration = lib.mkDefault (
      config.device.capabilities.hasGPU
    );

    services.display.multiMonitor = lib.mkDefault (
      config.device.profiles.isWorkstation or false
    );

    services.display.hidpi = lib.mkDefault (
      config.device.type == "laptop"
    );

    # Wayland-specific defaults
    services.display.waylandPortals = lib.mkDefault (
      config.services.display.backend == "wayland"
    );

    services.display.screenSharing = lib.mkDefault (
      config.services.display.backend == "wayland" && 
      (config.device.profiles.isWorkstation or false)
    );

    # Gaming defaults
    services.display.gaming = lib.mkDefault (
      config.device.profiles.isGaming or false
    );

    services.display.highRefreshRate = lib.mkDefault (
      config.services.display.gaming && config.device.capabilities.hasGPU
    );

    # Compositing defaults
    services.display.compositing = lib.mkDefault (
      config.device.capabilities.hasGPU && 
      config.services.display.desktopEnvironment != "i3"
    );
  };
}