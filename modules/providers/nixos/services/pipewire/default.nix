{ pkgs, ... }:
{

  imports = [ ./settings.nix ];

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
}
