# Main test runner for the Zyx configuration
{ lib, pkgs }:

let
  nixtest = import ./framework/nixtest.nix { inherit lib pkgs; };

  # Import all unit test suites
  unitTests = {
    platformDetection = import ./unit/platform/detection-test.nix { inherit lib pkgs; };
    deviceCapabilities = import ./unit/platform/capabilities-test.nix { inherit lib pkgs; };
  };

  # Run all unit tests
  unitTestResults = lib.mapAttrs (name: suite: nixtest.runTestSuite suite) unitTests;

  # Generate a summary report
  generateReport = results:
    let
      allSuites = lib.attrValues results;
      totalTests = lib.foldl' (acc: suite: acc + suite.total) 0 allSuites;
      passedTests = lib.foldl' (acc: suite: acc + suite.passed) 0 allSuites;
      failedSuites = lib.filter (suite: !suite.success) allSuites;
    in {
      inherit totalTests passedTests;
      failedTests = totalTests - passedTests;
      success = passedTests == totalTests;
      suites = results;
      summary = "Tests: ${toString passedTests}/${toString totalTests} passed";
      failedSuites = map (suite: suite.name) failedSuites;
    };

in {
  # Individual test results
  unit = unitTestResults;
  
  # Overall test report
  report = generateReport unitTestResults;
  
  # Convenience function to run all tests
  runAll = unitTestResults;
  
  # Check function for flake integration
  check = 
    let report = generateReport unitTestResults;
    in if report.success 
       then pkgs.writeText "test-success" report.summary
       else throw "Tests failed: ${lib.concatStringsSep ", " report.failedSuites}";
}