_: {
  mkExtendedLib = flake: nixpkgs: nixpkgs.lib.extend flake.lib.overlay;

  mkSpecialArgsForHome =
    {
      inputs,
      hostname,
      username,
      extendedLib,
      desktopConfig ? null,
    }:
    {
      inherit
        inputs
        hostname
        username
        desktopConfig
        ;
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
      userDesktops ? { },
    }:
    {
      inherit
        inputs
        hostname
        usernames
        userDesktops
        ;
      inherit (inputs) self;
      lib = extendedLib;
      flake-parts-lib = inputs.flake-parts.lib;
    };
}
