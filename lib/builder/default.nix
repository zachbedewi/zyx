{ inputs, ... }:
{
  buildHomeConfiguration = import ./home.nix { inherit inputs; };
  buildNixosSystem = import ./nixos.nix { inherit inputs; };
}
