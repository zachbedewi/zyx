# Unit tests for platform detection module
{ lib, pkgs }:

let
  testUtils = import ../../lib/test-utils.nix { inherit lib pkgs; };
  
  # Import the module under test
  platformModule = ../../../modules/platform/detection.nix;

  # Helper to evaluate config and extract specific paths
  testConfig = modules: (testUtils.evalConfig modules).config;

in {
  name = "platform-detection";
  tests = [
    {
      name = "platform-type-defaults-to-nixos-on-linux";
      expr = (testConfig [ platformModule ]).platform.type;
      expected = "nixos";
    }

    {
      name = "platform-detected-matches-type";
      expr = (testConfig [ 
        platformModule 
        { platform.type = "darwin"; }
      ]).platform.detected;
      expected = "darwin";
    }

    {
      name = "nixos-platform-supports-systemd";
      expr = (testConfig [ 
        platformModule 
        { platform.type = "nixos"; }
      ]).platform.capabilities.supportsSystemd;
      expected = true;
    }

    {
      name = "darwin-platform-does-not-support-systemd";
      expr = (testConfig [ 
        platformModule 
        { platform.type = "darwin"; }
      ]).platform.capabilities.supportsSystemd;
      expected = false;
    }

    {
      name = "all-platforms-support-home-manager";
      expr = (testConfig [ 
        platformModule 
        { platform.type = "droid"; }
      ]).platform.capabilities.supportsHomeManager;
      expected = true;
    }

    {
      name = "linux-platforms-are-detected";
      expr = (testConfig [ 
        platformModule 
        { platform.type = "nixos"; }
      ]).platform.capabilities.isLinux;
      expected = true;
    }

    {
      name = "darwin-platform-is-detected";
      expr = (testConfig [ 
        platformModule 
        { platform.type = "darwin"; }
      ]).platform.capabilities.isDarwin;
      expected = true;
    }

    # Test that invalid platform type fails assertion
    {
      name = "invalid-platform-type-fails";
      expr = testUtils.assertionShouldFail [
        platformModule
        { platform.type = "invalid"; }
      ];
      expected = true;
    }
  ];
}