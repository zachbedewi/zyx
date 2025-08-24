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
      _:
      {
        system,
        hostname,
        path,
        ...
      }:
      buildNixosSystem {
        inherit
          inputs
          system
          hostname
          path
          ;
      }
    ) (filterNixosHosts systemConfigurations);
  };
}
