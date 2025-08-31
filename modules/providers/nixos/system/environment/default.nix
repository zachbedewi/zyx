{ lib, ... }:
{
  config = {
    environment = {
      extraOutputsToInstall = [
        "bin"
        "dev"
        "doc"
        "include"
        "info"
        "share"
      ];

      pathsToLink = [
        "/bin"
        "/doc"
        "/etc"
        "/info"
        "/share"
        "/share/doc"
        "/usr/bin"
      ];

      variables =
        let
          pagerArgs = [
            "--RAW-CONTROL-CHARS"
            "--wheel-lines=5"
            "--LONG-PROMPT"
            "--no-vbell"
            "--wordwrap"
          ];
        in
        {
          SYSTEMD_PAGERSECURE = "true";
          PAGER = "less -FR";
          LESS = lib.concatStringsSep " " pagerArgs;
          SYSTEMD_LESS = lib.concatStringsSep " " (
            pagerArgs
            ++ [
              "--quit-if-one-screen"
              "--chop-long-lines"
              "--no-init"
            ]
          );
        };
    };
  };
}
