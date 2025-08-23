{ inputs, ... }:
let
  inherit (inputs.nixpkgs.lib)
    genAttrs
    foldl'
    filterAttrs
    ;

  getDirectoryNames = path: builtins.attrNames (builtins.readDir path);

  parseDelimittedHomeConfigIdentifier =
    identifier: delimiter:
    let
      parts = builtins.split delimiter identifier;
      username = builtins.elemAt parts 0;
      hostname = builtins.elemAt parts 2;
    in
    {
      inherit username hostname;
    };

  # Generate configuration metadata for all hosts with the given system
  # Return metadata as an attribute set with the following format:
  # {
  #   ${hostname} = {
  #     system = "${system-architecture}";
  #     hostname = "${hostname}";
  #     path = /path/to/host/configuration;
  #   }
  # }
  genHostConfigMetadataForSystem =
    hostsPath: system:
    let
      hostsForSystemArchitecturePath = hostsPath + "/${system}";
      hosts = getDirectoryNames hostsForSystemArchitecturePath;
    in
    genAttrs hosts (hostname: {
      inherit hostname system;
      path = hostsForSystemArchitecturePath + "/${hostname}";
    });

  # Generate configuration metadata for all homes with the given system
  # Return metadata as an attribute set with the following format:
  # {
  #   "${username}@${hostname}" = {
  #     system = "${system-architecture}";
  #     hostname = "${hostname}";
  #     username = "${username}";
  #     path = /path/to/home/configuration;
  #   }
  # }
  genHomeConfigMetadataForSystem =
    homesPath: system:
    let
      homesForSystemArchitecturePath = homesPath + "/${system}";
      homes = getDirectoryNames homesForSystemArchitecturePath;
    in
    genAttrs homes (
      userHost:
      let
        parsed = parseDelimittedHomeConfigIdentifier userHost "@";
      in
      {
        inherit system;
        inherit (parsed) hostname username;
        path = homesForSystemArchitecturePath + "/${userHost}";
      }
    );
in
{
  inherit getDirectoryNames;

  genAllHostConfigMetadata =
    hostsPath:
    let
      architectures = getDirectoryNames hostsPath;
    in
    foldl' (acc: system: acc // genHostConfigMetadataForSystem hostsPath system) { } architectures;

  genAllHomeConfigMetadata =
    homesPath:
    let
      architectures = getDirectoryNames homesPath;
    in
    foldl' (acc: system: acc // genHomeConfigMetadataForSystem homesPath system) { } architectures;

  filterNixosHosts =
    systems: filterAttrs (_hostname: { system, ... }: system == "x86_64-linux") systems;

  filterDarwinHosts =
    systems:
    filterAttrs (
      _hostname: { system, ... }: system == "aarch64-darwin" || system == "x86_64-darwin"
    ) systems;
}
