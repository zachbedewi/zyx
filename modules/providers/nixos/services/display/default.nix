{
  config,
  lib,
  userDesktops,
  ...
}:
let
  inherit (lib)
    mkIf
    unique
    filter
    mapAttrsToList
    ;

  # Get list of unique sessions needed across all users
  enabledSessions = unique (
    filter (s: s != null) (mapAttrsToList (_: d: d.session or null) userDesktops)
  );

  hasDesktop = enabledSessions != [ ];
in
{
  imports = [
    ./greetd
    ./sessions
  ];

  config = mkIf hasDesktop {
    zyx.services.display = {
      greetd.enable = true;
      sessions = lib.genAttrs enabledSessions (_: {
        enable = true;
      });
    };
  };
}
