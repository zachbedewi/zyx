{
  pkgs,
  lib,
  usernames,
  ...
}:
{
  config = {
    users = {
      defaultUserShell = pkgs.zsh;
      allowNoPasswordLogin = false;
      enforceIdUniqueness = true;

      users = lib.mkMerge [
        {
          root = {
            # Lock root
            hashedPassword = "*";
          };
        }
        (lib.listToAttrs (
          map (username: {
            name = username;
            value = {
              isNormalUser = true;

              createHome = true;
              home = "/home/${username}";

              useDefaultShell = true;

              initialHashedPassword = "$y$j9T$SUoqmnYrMvbqVIgktm4rl.$vRED9fj6Kxqp/XEpHd4/TS/JIMcBZTeqTM6fcG5D8r2";

              extraGroups = [
                "wheel"
                "audio"
                "video"
                "nix"
                "network"
                "networkmanager"
                "git"
              ];

            };
          }) usernames
        ))
      ];
    };
  };
}
