{ self, inputs, lib, ... }:
let
  inherit (self.lib.filesystem) genAllHomeConfigMetadata;
  inherit (self.lib.builder) buildHomeConfiguration;
  inherit (lib) mapAttrs;

  homeConfigurations = genAllHomeConfigMetadata ../homes;
in {
  imports = [
    inputs.home-manager.flakeModules.home-manager
  ];

  flake = {
    homeConfigurations = mapAttrs (
      name: {
        system,
        path,
        hostname,
        username,
        ...
      }:
      buildHomeConfiguration {
        inherit inputs system path hostname username;
      }
    ) homeConfigurations;
  };
}
