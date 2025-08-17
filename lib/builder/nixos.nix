{inputs}: {
  system,
  hostname,
  path,
  ...
}: let
  flake = inputs.self or (throw "buildNixosSystem requires 'inputs.self' to be passed.");
  common = import ./common.nix {inherit inputs;};
  extendedLib = common.mkExtendedLib flake inputs.nixpkgs;
  username = "skitzo";
in
  inputs.nixpkgs.lib.nixosSystem {
    inherit system;

    specialArgs = common.mkSpecialArgs {
      inherit
        inputs
        hostname
        username
        extendedLib
        ;
    };

    modules = [
      {_module.args.lib = extendedLib;}

      # External modules
      inputs.home-manager.nixosModules.home-manager
      inputs.stylix.nixosModules.stylix

      # Host's configuration module
      path
    ];
  }
