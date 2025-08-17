{inputs}: {
  mkExtendedLib = flake: nixpkgs: nixpkgs.lib.extend flake.lib.overlay;

  mkSpecialArgs = {
    inputs,
    hostname,
    username,
    extendedLib,
  }: {
    inherit inputs hostname username;
    inherit (inputs) self;
    lib = extendedLib;
    flake-parts-lib = inputs.flake-parts.lib;
  };
}
