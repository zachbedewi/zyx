{inputs, ...}: {
  buildNixosSystem = import ./nixos.nix {inherit inputs;};
}
