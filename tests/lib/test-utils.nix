# Common testing utilities for the Zyx configuration
{ lib, pkgs ? import <nixpkgs> {} }:

{
  # Evaluate a module configuration for testing
  evalConfig = modules: lib.evalModules {
    modules = modules ++ [
      # Provide minimal context for module evaluation
      { _module.check = false; }
    ];
    specialArgs = { inherit pkgs; };
  };

  # Create a test case for option evaluation
  mkOptionTest = { name, modules, expected, expectedError ? false }: {
    inherit name;
    expr = 
      if expectedError then
        builtins.tryEval (evalConfig modules).config
      else
        (evalConfig modules).config;
    inherit expected expectedError;
  };

  # Create mock hardware configuration for testing
  mkMockHardware = { 
    hasAudio ? false,
    hasGPU ? false, 
    hasWayland ? false,
    hasGUI ? false,
    deviceType ? "vm"
  }: {
    device = {
      type = deviceType;
      capabilities = {
        inherit hasAudio hasGPU hasWayland hasGUI;
      };
    };
  };

  # Helper to create platform-specific test configurations
  mkPlatformTest = platform: extraConfig: {
    platform.type = platform;
  } // extraConfig;

  # Assertion test helper
  assertionShouldFail = modules: 
    let result = builtins.tryEval (evalConfig modules).config;
    in !result.success;

  # Helper to extract specific config paths for testing
  getConfigPath = path: config: lib.attrByPath (lib.splitString "." path) null config;
}