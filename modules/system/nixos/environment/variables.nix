{ lib, ... }:
let
  inherit (lib.strings) concatStringsSep;
  pagerArgs = [
    "--RAW-CONTROL-CHARS"
    "--wheel-lines=5"
    "--LONG-PROMPT"
    "--no-vbell"
    "--wordwrap"
  ];
in
{
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    SUDO_EDITOR = "nvim";

    SYSTEMD_PAGERSECURE = "true";
    PAGER = "less -FR";
    LESS = concatStringsSep " " pagerArgs;
    SYSTEMD_LESS = concatStringsSep " " (
      pagerArgs
      ++ [
        "--quit-if-one-screen"
        "--chop-long-lines"
        "--no-init"
      ]
    );
  };
}
