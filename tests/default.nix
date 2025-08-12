# Main test runner for the Zyx configuration
{ lib, pkgs }:

let
  testUtils = import ./lib/test-utils.nix { inherit lib pkgs; };
  
  # Import unit test modules
  audioTests = import ./unit/services/audio-test.nix { inherit lib pkgs; };
  displayTests = import ./unit/services/display-test.nix { inherit lib pkgs; };
  
  # Run unit tests
  runUnitTests = testName: tests:
    let
      results = lib.listToAttrs (map (test: {
        name = "${testName}-${test.name}";
        value = 
          if test.expectedError or false then
            test.expr
          else if test.expected or null == null then 
            false  # Invalid test - no expected value
          else 
            test.expr == test.expected;
      }) tests);
    in results;
  
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

  # Run all unit tests
  audioUnitTests = runUnitTests "audio" audioTests.tests;
  displayUnitTests = runUnitTests "display" displayTests.tests;
  allUnitTests = audioUnitTests // displayUnitTests;
  
  # Combine all test results
  allTests = runBasicTests // allUnitTests;
  
  # Simple success check
  allTestsPassed = lib.all (x: x) (lib.attrValues allTests);

in {
  # Test results
  results = allTests;
  
  # Detailed results by category
  basicResults = runBasicTests;
  audioResults = audioUnitTests;
  displayResults = displayUnitTests;
  
  # Check function for flake integration
  check = 
    if allTestsPassed
    then pkgs.writeText "test-success" "All tests passed: ${toString (lib.length (lib.attrNames allTests))} total"
    else throw "Tests failed: ${builtins.toJSON (lib.filterAttrs (n: v: !v) allTests)}";
}