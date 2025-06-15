{
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkForce;
in {
  environment = {
    defaultPackages = mkForce [];

    systemPackages = with pkgs; [
      curl
      wget
      rsync
      lshw
      pciutils
      dnsutils
    ];
  };
}
