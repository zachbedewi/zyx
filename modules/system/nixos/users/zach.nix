{
  users.users.zach = {
    isNormalUser = true;

    createHome = true;
    home = "/home/zach";

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
}
