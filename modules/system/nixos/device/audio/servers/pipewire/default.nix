{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;

  inherit (config) modules;
  system = modules.system;
  device = modules.device;
in
{
  imports = [
    ./settings.nix
  ];

  config = mkIf (system.audio.enable && device.hasAudio) {
    services.pipewire = {
      enable = true;
      audio.enable = true;

      pulse.enable = true;
      jack.enable = true;
      alsa = {
        enable = true;
        support32Bit = pkgs.stdenv.isLinux && pkgs.stdenv.hostPlatform.isx86;
      };
    };

    systemd.user.services = {
      pipewire.wantedBy = [ "default.target" ];
      pipewire-pulse.wantedBy = [ "default.target" ];
    };
  };
}
