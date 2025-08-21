{
  self,
  inputs,
  lib,
  ...
}:
let
  inherit (self.lib.filesystem) genAllHostConfigMetadata filterNixosHosts;
  inherit (self.lib.builder) buildNixosSystem;
  inherit (lib) mapAttrs;

  systemConfigurations = genAllHostConfigMetadata ../systems;
in
{
  flake = {
    nixosConfigurations = mapAttrs (
      name:
      {
        system,
        path,
        hostname,
        ...
      }:
      buildNixosSystem {
        inherit
          inputs
          system
          path
          hostname
          ;
      }
    ) (filterNixosHosts systemConfigurations);
  };
}
