{pkgs, inputs, ...}: {
  config = {
    programs.emacs = {
      enable = true;
      package = pkgs.emacs;
    };

    home.file = {
      ".emacs.d/early-init.el".source = "${inputs.minimal-emacs}/early-init.el";
      ".emacs.d/init.el".source = "${inputs.minimal-emacs}/init.el";
    };
  };
}
