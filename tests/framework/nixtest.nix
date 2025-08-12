# NixTest framework integration for unit testing
{ lib, pkgs }:

let
  testUtils = import ../lib/test-utils.nix { inherit lib pkgs; };
  mockHardware = import ../lib/mock-hardware.nix { inherit lib; };

in {
  # Run a single test case
  runTest = testCase: 
    let
      result = builtins.tryEval testCase.expr;
    in
      if testCase.expectedError or false then
        # Test should fail
        if result.success then
          throw "Test '${testCase.name}' expected to fail but succeeded"
        else
          true
      else
        # Test should succeed
        if !result.success then
          throw "Test '${testCase.name}' failed to evaluate: ${result.value}"
        else if result.value != testCase.expected then
          throw "Test '${testCase.name}' failed: expected ${builtins.toJSON testCase.expected}, got ${builtins.toJSON result.value}"
        else
          true;

  # Run a test suite (list of test cases)
  runTestSuite = { name, tests }:
    let
      results = map runTest tests;
      passedTests = lib.length (lib.filter (x: x == true) results);
      totalTests = lib.length tests;
    in {
      inherit name;
      passed = passedTests;
      total = totalTests;
      success = passedTests == totalTests;
      results = lib.zipListsWith (test: result: {
        name = test.name;
        passed = result == true;
      }) tests results;
    };

  # Convenience function to create test cases
  inherit (testUtils) mkOptionTest;

  # Re-export utilities for easy access
  inherit testUtils mockHardware;

  # Helper to run all tests in a directory
  runAllTests = testDir:
    let
      testFiles = lib.filterAttrs (name: type: 
        type == "regular" && lib.hasSuffix "-test.nix" name
      ) (builtins.readDir testDir);
      
      testSuites = lib.mapAttrsToList (name: _: 
        import "${testDir}/${name}" { inherit lib pkgs; }
      ) testFiles;
    in
      map (suite: runTestSuite suite) testSuites;
}