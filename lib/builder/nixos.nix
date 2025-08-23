{ inputs }:
{
  system,
  hostname,
  path,
  ...
}:
let
  flake = inputs.self;
  common = import ./common.nix { inherit inputs; };

  inherit (flake.lib.filesystem) genAllHomeConfigMetadata;
  inherit (common) mkSpecialArgsForHost mkSpecialArgsForHome mkExtendedLib;

  extendedLib = mkExtendedLib flake inputs.nixpkgs;
  homeConfigMetadataForHost = builtins.filter (config: config.hostname == hostname) (
    builtins.attrValues (genAllHomeConfigMetadata (flake + "/homes"))
  );
  usernames = builtins.map ({ username, ... }: username) homeConfigMetadataForHost;

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
      home-manager.extraSpecialArgs = mkSpecialArgsForHome {
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

  specialArgs = mkSpecialArgsForHost {
    inherit
      inputs
      hostname
      usernames
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

    # This host's configuration module
    path
  ]
  # This host's home configurations
  ++ (builtins.map buildHomeModule homeConfigMetadataForHost);
}
