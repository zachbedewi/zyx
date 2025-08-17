{inputs}: {
  system,
  hostname,
  path,
  ...
}:
inputs.nixpkgs.lib.nixosSystem {
  inherit system;

  specialArgs = {
    inherit inputs hostname;
  };

  modules = [
    inputs.home-manager.nixosModules.home-manager
    inputs.stylix.nixosModules.stylix
    path
  ];
}
