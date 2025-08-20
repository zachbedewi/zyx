{
  pkgs,
  inputs,
  config,
  ...
}:
{
  config = {
    programs.emacs = {
      enable = true;
      package = pkgs.emacs;
    };

    # home.file = {
    # Minimal emacs-d framework
    # ".config/emacs/early-init.el".source = "${inputs.minimal-emacs}/early-init.el";
    # ".config/emacs/init.el".source = "${inputs.minimal-emacs}/init.el";

    # ".config/emacs/pre-early-init.el".source = config.lib.file.mkOutOfStoreSymlink ./config/pre-early-init.el;
    # ".config/emacs/post-init.el".source = config.lib.file.mkOutOfStoreSymlink ./config/post-init.el;
    # ".config/emacs/modules".source = config.lib.file.mkOutOfStoreSymlink ./config/modules;
    # };
  };
}
