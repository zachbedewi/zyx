# Main test runner for the Zyx configuration
{ lib, pkgs }:

let
  testUtils = import ./lib/test-utils.nix { inherit lib pkgs; };
  
  # Simple test runner that evaluates our core modules
  runBasicTests = {
    # Test platform detection
    platformDetection = (testUtils.evalConfig [ 
      ../modules/platform/detection.nix 
    ]).config.platform.type == "nixos";
    
    # Test device capabilities
    deviceCapabilities = 
      let 
        config = (testUtils.evalConfig [ 
          ../modules/platform/detection.nix
          ../modules/platform/capabilities.nix
          { device.type = "laptop"; }
        ]).config;
      in 
        config.device.capabilities.hasAudio == true &&
        config.device.capabilities.hasGPU == true &&
        config.device.profiles.isWorkstation == true;
  };

  # Simple success check
  allTestsPassed = lib.all (x: x) (lib.attrValues runBasicTests);

in {
  # Test results
  results = runBasicTests;
  
  # Check function for flake integration
  check = 
    if allTestsPassed
    then pkgs.writeText "test-success" "All basic tests passed"
    else throw "Basic tests failed: ${builtins.toJSON runBasicTests}";
}