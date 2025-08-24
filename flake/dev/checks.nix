{ inputs, lib, ... }:
{
  imports = lib.optional (inputs.git-hooks-nix ? flakeModule) inputs.git-hooks-nix.flakeModule;

  perSystem = _: {
    pre-commit = lib.mkIf (inputs.git-hooks-nix ? flakeModule) {

      settings.hooks = {
        deadnix.enable = true;
        statix.enable = true;
        treefmt.enable = true;
      };
    };
  };
}
