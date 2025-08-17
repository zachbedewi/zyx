{
  self,
  inputs,
  lib,
  ...
}: let
  inherit (self.lib.filesystem) genAllSystemConfigMetadata filterNixosConfigurations;
  inherit (self.lib.builder) buildNixosSystem;
  inherit (lib) mapAttrs;

  systemConfigurations = genAllSystemConfigMetadata ../systems;
in {
  flake = {
    nixosConfigurations = mapAttrs (
      name: {
        system,
        path,
        hostname,
        ...
      }:
        buildNixosSystem {
          inherit inputs system path hostname;
        }
    ) (filterNixosConfigurations systemConfigurations);
  };
}
