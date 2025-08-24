_: {
  mkExtendedLib = flake: nixpkgs: nixpkgs.lib.extend flake.lib.overlay;

  mkSpecialArgsForHome =
    {
      inputs,
      hostname,
      username,
      extendedLib,
    }:
    {
      inherit inputs hostname username;
      inherit (inputs) self;
      lib = extendedLib;
      flake-parts-lib = inputs.flake-parts.lib;
    };

  mkSpecialArgsForHost =
    {
      inputs,
      hostname,
      usernames,
      extendedLib,
    }:
    {
      inherit inputs hostname usernames;
      inherit (inputs) self;
      lib = extendedLib;
      flake-parts-lib = inputs.flake-parts.lib;
    };
}
