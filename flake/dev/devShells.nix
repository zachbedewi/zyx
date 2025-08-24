{
  perSystem =
    {
      config,
      pkgs,
      self',
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          nh
          deadnix
          statix
          sops
          self'.formatter
        ];

        shellHook = ''
          ${config.pre-commit.installationScript}
        '';
      };
    };
}
