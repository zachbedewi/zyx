{inputs, ...}: let
  inherit (inputs.nixpkgs.lib) genAttrs foldl';

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
in {
  inherit getDirectoryNames;

  genAllSystemConfigMetadata = systemsPath: let
    architectures = getDirectoryNames systemsPath;
  in
    foldl' (acc: system: acc // generateConfigurationMetadataForSystem systemsPath system) {} architectures;
}
