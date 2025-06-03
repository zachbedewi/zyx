{
  config = {
    programs.eza = {
      enable = true;
      icons = "auto";
      git = true;
      enableZshIntegration = false;
      extraOptions = [
        "--oneline"
        "--long"
        "--all"
        "--group-directories-first"
        "--header"
      ];
    };
  };
}
