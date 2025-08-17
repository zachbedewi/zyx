{ config, lib, ... }:
let
  inherit (lib) mkDefault mkIf;

  inherit (lib.options)
    mkEnableOption;

  cfg = config.zyx.services.openssh;
in {
  options.zyx.services.openssh = {
    enable = mkEnableOption "Enable OpenSSH.";
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;

      hostKeys = mkDefault [
        {
          bits = 4096;
          path = "/etc/ssh/ssh_host_rsa_key";
          type = "rsa";
        }
        {
          bits = 4096;
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];

      openFirewall = true;
      ports = [30];
      startWhenNeeded = true;

      settings = {
        PermitRootLogin = "no";

        PasswordAuthentication = false;
        AuthenticationMethods = "publickey";
        PubkeyAuthentication = "yes";
        ChallengeResponseAuthentication = "no";

        StreamLocalBindUnlink = "yes";

        UseDns = false;
        UsePAM = false;

        X11Forwarding = false;

        # key exchange algorithms recommended by `ssh-audit`
        KexAlgorithms = [
          "curve25519-sha256"
          "curve25519-sha256@libssh.org"
          "diffie-hellman-group16-sha512"
          "diffie-hellman-group18-sha512"
          "diffie-hellman-group-exchange-sha256"
          "sntrup761x25519-sha512@openssh.com"
        ];

        # message authentication code algorithms recommended by `ssh-audit`
        Macs = [
          "hmac-sha2-512-etm@openssh.com"
          "hmac-sha2-256-etm@openssh.com"
          "umac-128-etm@openssh.com"
        ];
      };
    };
  };
}
