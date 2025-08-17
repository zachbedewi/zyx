{inputs, ...}: let
  inherit
    (inputs.nixpkgs.lib)
    genAttrs
    foldl'
    filterAttrs
    ;

  getDirectoryNames = path: builtins.attrNames (builtins.readDir path);

  # Generates the configuration metadata for a single system.
  # Ex:
  # {
  #   eye-of-god = {
  #     hostname = "eye-of-god";
  #     path = /dev/zyx/systems/x86_64-linux/eye-of-god;
  #     system = "x86_64-linux";
  #   }
  #   fried-egg = {
  #     hostname = "fried-egg";
  #     path = /dev/zyx/systems/x86_64-linux/fried-egg;
  #     system = "x86_64-linux";
  #   }
  # }
  generateConfigurationMetadataForSystem = systemsPath: system: let
    systemConfigurationPath = systemsPath + "/${system}";
    hosts = getDirectoryNames systemConfigurationPath;
  in
    genAttrs hosts (hostname: {
      inherit system hostname;
      path = systemConfigurationPath + "/${hostname}";
    });

  # Generates home-manager configuration metadata for a single system.
  # Ex:
  # {
  #   "skitzo@eye-of-god" = {
  #     system = "x86_64-linux";
  #     hostname = "eye-of-god";
  #     username = "skitzo";
  #     path = /dev/zyx/homes/x86_64-linux/skitzo@eye-of-god;
  #   };
  #   "zach@eye-of-god" = {
  #     system = "x86_64-linux";
  #     hostname = "eye-of-god";
  #     username = "zach";
  #     path = /dev/zyx/homes/x86_64-linux/zach@eye-of-god;
  #   };
  # }
  generateHomeConfigurationMetadataForSystem = homesPath: system: let
    systemHomesPath = homesPath + "/${system}";
    homeConfigs = getDirectoryNames systemHomesPath;
    parseUserHost = userHost: let
      parts = builtins.split "@" userHost;
      username = builtins.elemAt parts 0;
      hostname = builtins.elemAt parts 2;
    in {
      inherit username hostname;
    };
  in
    genAttrs homeConfigs (userHost: let
      parsed = parseUserHost userHost;
    in {
      inherit system;
      inherit (parsed) username hostname;
      path = systemHomesPath + "/${userHost}";
    });
in {
  inherit getDirectoryNames;

  genAllSystemConfigMetadata = systemsPath: let
    architectures = getDirectoryNames systemsPath;
  in
    foldl' (acc: system: acc // generateConfigurationMetadataForSystem systemsPath system) {} architectures;

  genAllHomeConfigMetadata = homesPath: let
    architectures = getDirectoryNames homesPath;
  in
    foldl' (acc: system: acc // generateHomeConfigurationMetadataForSystem homesPath system) {} architectures;

  filterNixosConfigurations = systems:
    filterAttrs (
      _hostname: {system, ...}: system == "x86_64-linux"
    )
    systems;
}
