{ inputs, ... }:
{
  flake.lib = {
    filesystem = import ./filesystem { inherit inputs; };
    builder = import ./builder { inherit inputs; };
    overlay = import ./overlay { inherit inputs; };
  };
}
