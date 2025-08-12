# Unit tests for device capabilities module
{ lib, pkgs }:

let
  testUtils = import ../../lib/test-utils.nix { inherit lib pkgs; };
  mockHardware = import ../../lib/mock-hardware.nix { inherit lib; };
  
  # Import modules under test
  platformModule = ../../../modules/platform/detection.nix;
  capabilitiesModule = ../../../modules/platform/capabilities.nix;

  # Helper to evaluate config and extract specific paths
  testConfig = modules: (testUtils.evalConfig modules).config;

in {
  name = "device-capabilities";
  tests = [
    # Test default capabilities for different device types
    {
      name = "laptop-has-audio-by-default";
      expr = (testConfig [ 
        platformModule 
        capabilitiesModule 
        { device.type = "laptop"; }
      ]).device.capabilities.hasAudio;
      expected = true;
    }

    {
      name = "server-has-no-audio-by-default";
      expr = (testConfig [ 
        platformModule 
        capabilitiesModule 
        { device.type = "server"; }
      ]).device.capabilities.hasAudio;
      expected = false;
    }

    {
      name = "laptop-has-gpu-by-default";
      expr = (testConfig [ 
        platformModule 
        capabilitiesModule 
        { device.type = "laptop"; }
      ]).device.capabilities.hasGPU;
      expected = true;
    }

    {
      name = "desktop-supports-wayland";
      expr = (testConfig [ 
        platformModule 
        capabilitiesModule 
        { 
          device.type = "desktop";
          platform.type = "nixos";
        }
      ]).device.capabilities.hasWayland;
      expected = true;
    }

    # Test capability dependencies with assertion failures
    {
      name = "wayland-without-gpu-fails-assertion";
      expr = testUtils.assertionShouldFail [
        platformModule
        capabilitiesModule
        {
          device = {
            type = "laptop";
            capabilities = {
              hasGUI = true;
              hasGPU = false;
              hasWayland = true;
            };
          };
        }
      ];
      expected = true;
    }

    {
      name = "wayland-without-gui-fails-assertion";
      expr = testUtils.assertionShouldFail [
        platformModule
        capabilitiesModule
        {
          device = {
            type = "server";
            capabilities = {
              hasGUI = false;
              hasGPU = true;
              hasWayland = true;
            };
          };
        }
      ];
      expected = true;
    }

    {
      name = "wayland-on-darwin-fails-assertion";
      expr = testUtils.assertionShouldFail [
        platformModule
        capabilitiesModule
        {
          platform.type = "darwin";
          device = {
            type = "laptop";
            capabilities = {
              hasGUI = true;
              hasGPU = true;
              hasWayland = true;
            };
          };
        }
      ];
      expected = true;
    }

    # Test device profiles
    {
      name = "server-is-headless";
      expr = (testConfig [ 
        platformModule 
        capabilitiesModule 
        { device.type = "server"; }
      ]).device.profiles.isHeadless;
      expected = true;
    }

    {
      name = "laptop-is-workstation";
      expr = (testConfig [ 
        platformModule 
        capabilitiesModule 
        { device.type = "laptop"; }
      ]).device.profiles.isWorkstation;
      expected = true;
    }

    {
      name = "laptop-is-development-machine";
      expr = (testConfig [ 
        platformModule 
        capabilitiesModule 
        { device.type = "laptop"; }
      ]).device.profiles.isDevelopmentMachine;
      expected = true;
    }

    {
      name = "server-is-not-workstation";
      expr = (testConfig [ 
        platformModule 
        capabilitiesModule 
        { device.type = "server"; }
      ]).device.profiles.isWorkstation;
      expected = false;
    }

    # Test with mock hardware configurations
    {
      name = "mock-laptop-config-has-wayland";
      expr = (testConfig [ 
        platformModule 
        capabilitiesModule 
        mockHardware.configs.laptop
      ]).device.capabilities.hasWayland;
      expected = true;
    }

    {
      name = "mock-server-config-is-headless";
      expr = (testConfig [ 
        platformModule 
        capabilitiesModule 
        mockHardware.configs.server
      ]).device.profiles.isHeadless;
      expected = true;
    }
  ];
}