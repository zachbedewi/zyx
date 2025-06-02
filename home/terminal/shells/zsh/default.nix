{config, ...}: {
  imports = [
    ./plugins.nix
  ];

  config = {
    programs.zsh = {
      enable = true;
      dotDir = ".config/zsh";
      enableCompletion = true;
      enableVteIntegration = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      sessionVariables = {LC_ALL = "en_US.UTF-8";};

      history = {
        # Share history between different zsh session
        share = true;

        # Saves timestamps to the histfile
        extended = true;

        # Optimize the size of the histfile
        save = 100000;
        size = 100000;
        expireDuplicatesFirst = true;
        ignoreDups = true;
        ignoreSpace = true;
      };
    };
  };
}
