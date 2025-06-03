{
  config,
  lib,
  ...
}: let
  inherit (lib.strings) fileContents;
in {
  imports = [
    ./aliases.nix
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
        # Share history between different zsh sessions
        share = true;

        # Put the histfile where it should be
        path = "${config.xdg.dataHome}/zsh/zsh_history";

        # Save timestamps to the histfile
        extended = true;

        # Optimize the size of the histfile
        save = 100000;
        size = 100000;
        expireDuplicatesFirst = true;
        ignoreDups = true;
        ignoreSpace = true;
      };

      # Allow for an easy way to cd directly to a specific directory using an alias
      # Ex. `cd ~dev` = `cd ~/dev`
      dirHashes = {
        dev = "$HOME/dev";
      };

      # Disable /etc/{zshrc,zprofile} to avoid precedence issues
      envExtra = ''
        setopt no_global_rcs
      '';

      initExtra = ''
        ${fileContents ./config/completion.zsh}
      '';
    };
  };
}
