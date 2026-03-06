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

  # Aggregate desktop configurations from all users on this host
  userDesktops = builtins.listToAttrs (
    builtins.map (cfg: {
      name = cfg.username;
      value = cfg.desktop;
    }) homeConfigMetadataForHost
  );

  buildHomeModule =
    {
      path,
      hostname,
      username,
      desktop,
      ...
    }:
    {
      home-manager = {
        backupFileExtension = "hm.old";

        users.${username} = {
          imports = [
            { _module.args.lib = extendedLib; }

            path
          ];
          _module.args = mkSpecialArgsForHome {
            inherit
              inputs
              hostname
              username
              extendedLib
              ;
            desktopConfig = desktop;
          };
        };
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
      userDesktops
      ;
  };

  modules = [
    { _module.args.lib = extendedLib; }

    # External modules
    inputs.home-manager.nixosModules.home-manager
    inputs.stylix.nixosModules.stylix
    inputs.sops-nix.nixosModules.sops

    # Custom modules
    ../../modules/profiles
    ../../modules/roles
    ../../modules/providers/common
    ../../modules/providers/nixos

    # This host's configuration module
    path
  ]
  # This host's home configurations
  ++ (builtins.map buildHomeModule homeConfigMetadataForHost);
}
