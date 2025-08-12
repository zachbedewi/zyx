# Mock hardware configurations for testing
{ lib }:

{
  # Standard test configurations for different device types
  configs = {
    # Minimal VM configuration
    vm = {
      device = {
        type = "vm";
        capabilities = {
          hasAudio = false;
          hasGPU = false;
          hasWayland = false;
          hasGUI = false;
          supportsCompositing = false;
        };
      };
      platform.type = "nixos";
    };

    # Basic laptop configuration
    laptop = {
      device = {
        type = "laptop";
        capabilities = {
          hasAudio = true;
          hasGPU = true;
          hasWayland = true;
          hasGUI = true;
          supportsCompositing = true;
        };
      };
      platform.type = "nixos";
    };

    # High-end desktop configuration
    desktop = {
      device = {
        type = "desktop";
        capabilities = {
          hasAudio = true;
          hasGPU = true;
          hasWayland = true;
          hasGUI = true;
          supportsCompositing = true;
        };
      };
      platform.type = "nixos";
    };

    # Headless server configuration
    server = {
      device = {
        type = "server";
        capabilities = {
          hasAudio = false;
          hasGPU = false;
          hasWayland = false;
          hasGUI = false;
          supportsCompositing = false;
        };
      };
      platform.type = "nixos";
    };

    # macOS laptop configuration
    macbookPro = {
      device = {
        type = "laptop";
        capabilities = {
          hasAudio = true;
          hasGPU = true;
          hasWayland = false;  # macOS doesn't support Wayland
          hasGUI = true;
          supportsCompositing = true;
        };
      };
      platform.type = "darwin";
    };
  };

  # Helper functions to create custom configurations
  mkCustomConfig = { deviceType, platform, capabilities }: {
    device = {
      type = deviceType;
      inherit capabilities;
    };
    platform.type = platform;
  };

  # Invalid configurations for testing error conditions
  invalidConfigs = {
    # Wayland without GPU
    waylandWithoutGPU = {
      device = {
        type = "laptop";
        capabilities = {
          hasAudio = true;
          hasGPU = false;
          hasWayland = true;
          hasGUI = true;
          supportsCompositing = false;
        };
      };
    };

    # Compositing without GUI
    compositingWithoutGUI = {
      device = {
        type = "server";
        capabilities = {
          hasAudio = false;
          hasGPU = true;
          hasWayland = false;
          hasGUI = false;
          supportsCompositing = true;
        };
      };
    };

    # GUI without any display capability
    guiWithoutDisplay = {
      device = {
        type = "desktop";
        capabilities = {
          hasAudio = true;
          hasGPU = false;
          hasWayland = false;
          hasGUI = true;
          supportsCompositing = false;
        };
      };
    };
  };
}