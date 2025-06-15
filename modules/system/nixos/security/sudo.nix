{
  pkgs,
  lib,
  ...
}: let
  inherit (lib.modules) mkDefault mkForce;
  inherit (lib.meta) getExe';
in {
  security = {
    sudo-rs.enable = mkForce false;

    sudo = {
      enable = true;

      execWheelOnly = mkForce true;

      extraConfig = ''
               Defaults lecture = never # rollback results in sudo lectures after each reboot
        Defaults pwfeedback # Make typed password visible as asterisks
        Defaults env_keep += "EDITOR PATH DISPLAY" # variables that will be passed to the root account
        Defaults timestamp_timeout = 300 # Makes sudo ask for password every 5 minutes
      '';
    };
  };
}
