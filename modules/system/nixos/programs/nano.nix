{ pkgs, ... }:
{
  programs.nano = {
    enable = true;
    nanorc = ''
      include ${pkgs.nanorc}/share/*.nanorc # extended syntax highlighting

      # Options
      # https://github.com/davidhcefx/Modern-Nano-Keybindings
      set tabsize 4
      set tabstospaces
      set linenumbers
      set numbercolor yellow,normal
      set indicator			# side-bar for indicating current position
      set smarthome			# `Home` jumps to line start first
      set afterends			# `Ctrl+Right` move to word ends instead of word starts
      set wordchars "_"			# recognize '_' as part of a word
      set zap				# delete selected text as a whole
      set historylog			# remember search history
      set multibuffer			# read files in multibuffer instead of insert
      set mouse				# enable mouse support
      bind M-R 	redo		main
      bind ^C	copy		main
      bind ^X 	cut		main
      bind ^V	paste		main
      bind ^K	zap		main
      bind ^H	chopwordleft	all
      bind ^Q	exit		all
      bind ^Z	suspend		main
      bind M-/	comment		main
      bind ^Space complete	main

      bind M-C 	location	main
      bind ^E	wherewas	all
      bind M-E	findprevious	all
      bind ^R	replace		main
      bind ^B	pageup		all
      bind ^F	pagedown	all
      bind ^G 	firstline	all
      bind M-G	lastline	all

      bind M-1 	help		all
      bind Sh-M-C constantshow	main
      bind Sh-M-F formatter	main
      bind Sh-M-B linter	main
    '';
  };
}
