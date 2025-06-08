{
  config,
  pkgs,
  ...
}: {
  config = {
    programs.bat = {
      enable = true;
      extraPackages = builtins.attrValues {
        inherit
          (pkgs.bat-extras)
          batgrep
          batdiff
          batman
          ;
      };
    };
  };
}
