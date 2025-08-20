{ inputs }:
{
  system,
  hostname,
  path,
  ...
}:
let
  flake = inputs.self or (throw "buildNixosSystem requires 'inputs.self' to be passed.");
  common = import ./common.nix { inherit inputs; };
  extendedLib = common.mkExtendedLib flake inputs.nixpkgs;
  username = "skitzo";

  # Build home configuration modules for this hostname
  inherit (flake.lib.filesystem) genAllHomeConfigMetadata;
  allHomeConfigs = genAllHomeConfigMetadata (flake + "/homes");

  # Filter home configurations for this specific hostname
  homeConfigsForHost = builtins.filter (config: config.hostname == hostname) (
    builtins.attrValues allHomeConfigs
  );

  # Function to build a home configuration module
  buildHomeModule =
    {
      system,
      path,
      hostname,
      username,
      ...
    }:
    {
      home-manager.users.${username} = {
        imports = [
          { _module.args.lib = extendedLib; }
          path
        ];
      };
      home-manager.extraSpecialArgs = common.mkSpecialArgs {
        inherit
          inputs
          hostname
          username
          extendedLib
          ;
      };
    };
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
    { _module.args.lib = extendedLib; }

    # External modules
    inputs.home-manager.nixosModules.home-manager
    inputs.stylix.nixosModules.stylix

    # Custom modules
    ../../modules/roles
    ../../modules/providers/nixos

    # Host's configuration module
    path
  ]
  ++ (builtins.map buildHomeModule homeConfigsForHost);
}
