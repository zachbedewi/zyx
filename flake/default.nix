{ inputs, ... }:
{
  imports = [
    ../lib
    ./configurations.nix
    ./homes.nix

    inputs.flake-parts.flakeModules.partitions
  ];

  partitions.dev = {
    module = ./dev;
    extraInputsFlake = ./dev;
  };

  partitionedAttrs = inputs.nixpkgs.lib.genAttrs [
    "checks"
    "devShells"
    "formatter"
  ] (_: "dev");
}
