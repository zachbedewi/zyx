{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.trivial) pipe;
  inherit (lib.types) isType;
  inherit (lib.attrsets)
    mapAttrsToList
    filterAttrs
    mapAttrs
    mapAttrs'
    ;
in
{
  nix =
    let
      mappedRegistry = pipe inputs [
        (filterAttrs (_: isType "flake"))
        (mapAttrs (_: flake: { inherit flake; }))
        (flakes: flakes // { nixpkgs.flake = inputs.nixpkgs; })
      ];
    in
    {
      package = pkgs.lix;

      registry = mappedRegistry // {
        default-flake = mappedRegistry.nixpkgs;
      };

      nixPath = mapAttrsToList (key: _: "${key}=flake:${key}") config.nix.registry;

      daemonCPUSchedPolicy = "idle";
      daemonIOSchedClass = "idle";
      daemonIOSchedPriority = 7;

      gc = {
        automatic = true;
        dates = "Sat *-*-* 03:00";
        options = "--delete-older-than 30d";
        persistent = true;
      };

      optimise = {
        automatic = true;
        dates = [ "04:00" ];
      };

      settings = {
        use-xdg-base-directories = true;

        use-registries = true;
        flake-registry = pkgs.writeText "flakes-empty.json" (
          builtins.toJSON {
            flakes = [ ];
            version = 2;
          }
        );

        min-free = "${toString (5 * 1024 * 1024 * 1024)}";
        max-free = "${toString (10 * 1024 * 1024 * 1024)}";

        auto-optimise-store = true;

        allowed-users = [
          "root"
          "@wheel"
        ];
        trusted-users = [
          "root"
          "@wheel"
        ];

        max-jobs = "auto";

        sandbox = true;
        sandbox-fallback = false;

        system-features = [
          "nixos-test"
          "kvm"
          "recursive-nix"
          "big-parallel"
        ];

        keep-going = true;

        stalled-download-timeout = 20;

        log-lines = 30;

        extra-experimental-features = [
          "flakes"
          "nix-command"
          "recursive-nix"
          "auto-allocate-uids"
          "cgroups"
          "repl-flake"
          "no-url-literals"
          "dynamic-derivations"
        ];

        pure-eval = false;

        warn-dirty = false;

        http-connections = 35;

        accept-flake-config = false;

        use-cgroups = pkgs.stdenv.isLinux;

        keep-derivations = true;
        keep-outputs = true;
      };
    };

  systemd.services.nix-gc = {
    unitConfig.ConditionCPower = true;
  };
}
