{config, ...}: let
  system = config.modules.system;
in {
  hardware.pulseaudio.enable = system.audio.enable && !config.services.pipewire.enable;
}
