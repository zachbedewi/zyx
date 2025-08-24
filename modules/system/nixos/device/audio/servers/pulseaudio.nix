{ config, ... }:
let
  inherit (config.modules) system;
in
{
  hardware.pulseaudio.enable = system.audio.enable && !config.services.pipewire.enable;
}
