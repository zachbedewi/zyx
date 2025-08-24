{
  inputs,
  config,
  lib,
  ...
}:
let
  sopsFolder = builtins.toString inputs.zyx-secrets + "/sops";

  cfg = config.zyx.security.sops;
in
{
  options.zyx.security.sops = {
    enable = lib.mkEnableOption "sops";
  };

  config = lib.mkIf cfg.enable {
    sops = {

      defaultSopsFile = "${sopsFolder}/secrets.yaml";
      validateSopsFiles = false;

      age = {
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        keyFile = "/var/lib/sops-nix/key.txt";
        generateKey = true;
      };

      secrets = {
        "zach-password" = { };
      };
    };
  };
}
