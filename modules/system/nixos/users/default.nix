{ pkgs, ... }:
{
  imports = [
    ./root.nix
    ./zach.nix
    ./skitzo.nix
  ];

  config = {
    users = {
      defaultUserShell = pkgs.zsh;
      allowNoPasswordLogin = false;
      enforceIdUniqueness = true;
    };
  };
}
