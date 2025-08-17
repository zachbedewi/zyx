{inputs}: {
  system,
  path,
  hostname,
  username,
  ...
}: let
  flake = inputs.self or (throw "buildHomeConfiguration requires 'inputs.self' to be passed.");
  common = import ./common.nix {inherit inputs;};
  extendedLib = common.mkExtendedLib flake inputs.nixpkgs;
in inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = import inputs.nixpkgs-unstable {
    inherit system;
  };

  extraSpecialArgs = common.mkSpecialArgs {
    inherit
      inputs
      hostname
      username
      extendedLib
      ;
  };

  modules = [
    {_module.args.lib = extendedLib;}

    # User/host specific configuration module
    path
  ];
}
