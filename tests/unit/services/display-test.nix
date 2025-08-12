# Display service unit tests
{ lib, pkgs }:

let
  testUtils = import ../../lib/test-utils.nix { inherit lib pkgs; };
  
  # Modules under test
  platformModule = ../../../modules/platform/detection.nix;
  capabilitiesModule = ../../../modules/platform/capabilities.nix;
  displayInterfaceModule = ../../../modules/services/display/interface.nix;
  displayNixOSModule = ../../../modules/services/display/nixos.nix;
  
  # Helper to create test configurations
  testConfig = modules: (testUtils.evalConfig (modules ++ [
    platformModule
    capabilitiesModule
    displayInterfaceModule
    displayNixOSModule
  ])).config;

in {
  name = "display-service";
  tests = [
    # Basic functionality tests
    {
      name = "display-service-defaults-enabled-with-gui";
      expr = (testConfig [
        { device.type = "laptop"; }
      ]).services.display.enable;
      expected = true;
    }

    {
      name = "display-service-disabled-without-gui";
      expr = (testConfig [
        { 
          device.type = "server";
          device.capabilities.hasGUI = false;
        }
      ]).services.display.enable;
      expected = false;
    }

    # Backend selection tests
    {
      name = "x11-backend-default-on-linux-without-wayland";
      expr = (testConfig [
        { 
          device.type = "desktop";
          device.capabilities.hasWayland = false;
        }
      ]).services.display.backend;
      expected = "x11";
    }

    {
      name = "wayland-backend-preferred-with-capability";
      expr = (testConfig [
        { 
          device.type = "laptop";
          device.capabilities.hasWayland = true;
        }
      ]).services.display.backend;
      expected = "wayland";
    }

    # Desktop environment tests
    {
      name = "kde-default-desktop-environment";
      expr = (testConfig [
        { device.type = "laptop"; }
      ]).services.display.desktopEnvironment;
      expected = "kde";
    }

    # Hardware capability tests
    {
      name = "acceleration-enabled-with-gpu";
      expr = (testConfig [
        { 
          device.type = "desktop";
          device.capabilities.hasGPU = true;
        }
      ]).services.display.acceleration;
      expected = true;
    }

    {
      name = "acceleration-disabled-without-gpu";
      expr = (testConfig [
        { 
          device.type = "vm";
          device.capabilities.hasGPU = false;
        }
      ]).services.display.acceleration;
      expected = false;
    }

    # Multi-monitor tests
    {
      name = "multimonitor-enabled-for-workstation";
      expr = (testConfig [
        { 
          device.type = "desktop";
          device.capabilities.hasMultiMonitor = true;
        }
      ]).services.display.multiMonitor;
      expected = true;
    }

    # HiDPI tests
    {
      name = "hidpi-enabled-for-laptops";
      expr = (testConfig [
        { 
          device.type = "laptop";
          device.capabilities.hasHiDPI = true;
        }
      ]).services.display.hidpi;
      expected = true;
    }

    # Gaming configuration tests
    {
      name = "gaming-enabled-for-gaming-profile";
      expr = (testConfig [
        { 
          device.type = "desktop";
          device.capabilities.hasGPU = true;
          device.capabilities.hasAudio = true;
        }
      ]).services.display.gaming;
      expected = true;
    }

    {
      name = "high-refresh-rate-with-gaming-and-gpu";
      expr = (testConfig [
        { 
          device.type = "desktop";
          device.capabilities.hasGPU = true;
          device.capabilities.hasAudio = true;
          device.capabilities.hasHighRefreshRate = true;
        }
      ]).services.display.highRefreshRate;
      expected = true;
    }

    # VR support tests
    {
      name = "vr-support-with-capable-hardware";
      expr = (testConfig [
        { 
          device.type = "desktop";
          device.capabilities.hasGPU = true;
          device.capabilities.supportsVR = true;
        }
      ]).services.display.vrSupport;
      expected = false;  # Should be false by default even with capability
    }

    {
      name = "vr-support-when-explicitly-enabled";
      expr = (testConfig [
        { 
          device.type = "desktop";
          device.capabilities.hasGPU = true;
          device.capabilities.supportsVR = true;
          services.display.vrSupport = true;
        }
      ]).services.display.vrSupport;
      expected = true;
    }

    # Wayland-specific tests
    {
      name = "wayland-portals-enabled-with-wayland";
      expr = (testConfig [
        { 
          device.type = "laptop";
          device.capabilities.hasWayland = true;
          services.display.backend = "wayland";
        }
      ]).services.display.waylandPortals;
      expected = true;
    }

    {
      name = "screen-sharing-enabled-for-workstation-wayland";
      expr = (testConfig [
        { 
          device.type = "desktop";
          device.capabilities.hasWayland = true;
          services.display.backend = "wayland";
        }
      ]).services.display.screenSharing;
      expected = true;
    }

    # Compositing tests
    {
      name = "compositing-enabled-with-gpu-and-de";
      expr = (testConfig [
        { 
          device.type = "laptop";
          device.capabilities.hasGPU = true;
          services.display.desktopEnvironment = "kde";
        }
      ]).services.display.compositing;
      expected = true;
    }

    {
      name = "compositing-disabled-for-i3";
      expr = (testConfig [
        { 
          device.type = "laptop";
          device.capabilities.hasGPU = true;
          services.display.desktopEnvironment = "i3";
        }
      ]).services.display.compositing;
      expected = false;
    }

    # Assertion failure tests
    {
      name = "display-service-requires-gui-capability";
      expr = testUtils.assertionShouldFail [
        platformModule
        capabilitiesModule
        displayInterfaceModule
        { 
          device.type = "server";
          device.capabilities.hasGUI = false;
          services.display.enable = true;
        }
      ];
      expectedError = true;
    }

    {
      name = "acceleration-requires-gpu-capability";
      expr = testUtils.assertionShouldFail [
        platformModule
        capabilitiesModule
        displayInterfaceModule
        { 
          device.type = "vm";
          device.capabilities.hasGPU = false;
          services.display.acceleration = true;
        }
      ];
      expectedError = true;
    }

    {
      name = "wayland-backend-requires-wayland-capability";
      expr = testUtils.assertionShouldFail [
        platformModule
        capabilitiesModule
        displayInterfaceModule
        { 
          device.type = "desktop";
          device.capabilities.hasWayland = false;
          services.display.backend = "wayland";
        }
      ];
      expectedError = true;
    }

    {
      name = "vr-support-requires-acceleration-and-gpu";
      expr = testUtils.assertionShouldFail [
        platformModule
        capabilitiesModule
        displayInterfaceModule
        { 
          device.type = "vm";
          device.capabilities.hasGPU = false;
          services.display.vrSupport = true;
        }
      ];
      expectedError = true;
    }

    {
      name = "hyprland-requires-wayland-backend";
      expr = testUtils.assertionShouldFail [
        platformModule
        capabilitiesModule
        displayInterfaceModule
        { 
          device.type = "desktop";
          services.display.backend = "x11";
          services.display.desktopEnvironment = "hyprland";
        }
      ];
      expectedError = true;
    }

    {
      name = "sway-requires-wayland-backend";
      expr = testUtils.assertionShouldFail [
        platformModule
        capabilitiesModule
        displayInterfaceModule
        { 
          device.type = "desktop";
          services.display.backend = "x11";
          services.display.desktopEnvironment = "sway";
        }
      ];
      expectedError = true;
    }

    # Implementation details tests
    {
      name = "implementation-stores-backend-info";
      expr = (testConfig [
        { 
          device.type = "laptop";
          services.display.backend = "wayland";
        }
      ]).services.display._implementation.backend;
      expected = "wayland";
    }

    {
      name = "implementation-stores-desktop-environment";
      expr = (testConfig [
        { 
          device.type = "desktop";
          services.display.desktopEnvironment = "gnome";
        }
      ]).services.display._implementation.desktopEnvironment;
      expected = "gnome";
    }

    {
      name = "implementation-tracks-acceleration-status";
      expr = (testConfig [
        { 
          device.type = "desktop";
          device.capabilities.hasGPU = true;
        }
      ]).services.display._implementation.acceleration;
      expected = true;
    }

    {
      name = "implementation-tracks-gaming-status";
      expr = (testConfig [
        { 
          device.type = "desktop";
          device.capabilities.hasGPU = true;
          device.capabilities.hasAudio = true;
        }
      ]).services.display._implementation.gamingEnabled;
      expected = true;
    }

    # Edge case tests
    {
      name = "display-service-works-with-minimal-vm";
      expr = (testConfig [
        { 
          device.type = "vm";
          device.capabilities.hasGUI = true;
          device.capabilities.hasGPU = false;
        }
      ]).services.display.enable;
      expected = true;
    }

    {
      name = "display-backend-auto-detection-vm";
      expr = (testConfig [
        { 
          device.type = "vm";
          device.capabilities.hasGUI = true;
          device.capabilities.hasWayland = false;
        }
      ]).services.display.backend;
      expected = "x11";
    }
  ];
}