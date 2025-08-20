{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) getExe;
in
{
  config = {
    programs.zsh.shellAliases = {
      ls = "${getExe pkgs.eza} --long --all --group-directories-first --header";
      cat = "${getExe pkgs.bat}";
    };
  };
}
