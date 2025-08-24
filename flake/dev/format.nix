{
  inputs,
  lib,
  ...
}:
{
  imports = lib.optional (inputs.treefmt-nix ? flakeModule) inputs.treefmt-nix.flakeModule;

  perSystem =
    { pkgs, ... }:
    {
      treefmt = lib.mkIf (inputs.treefmt-nix ? flakeModule) {
        flakeCheck = true;
        flakeFormatter = true;

        projectRootFile = "flake.nix";

        programs = {
          deadnix = {
            enable = true;
            no-lambda-arg = true;
          };
          nixfmt = {
            enable = true;
            package = pkgs.nixfmt;
          };
          statix.enable = true;
          yamlfmt.enable = true;
        };

        settings = {
          global.excludes = [
            "*.editorconfig"
            "*.envrc"
            "*.gitconfig"
            "*.git-blame-ignore-revs"
            "*.gitignore"
            "*.gitattributes"
            "*flake.lock"
            "*.conf"
            "*.gif"
            "*.ico"
            "*.ini"
            "*.png"
            "*.svg"
            "*.tmux"
            "*Makefile"
          ];
        };
      };
    };
}
