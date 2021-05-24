{ config, lib, pkgs, ... }:

{
  # This is here because usually you set this in the bashrc per-user, so I'll probably look for it in bash configs next time i need to make a change
  programs.bash = {
    #enableLsColors = true;
    #enableCompletion = true;
    shellInit = ''
    PATH=$PATH:/home/brody/minecraft
    '';






    promptInit = ''
      PATH=$PATH:/home/brody/minecraft    
      shopt -s histappend
      HISTCONTROL=ignoreboth
      HISTSIZE=10000
      HISTFILESIZE=20000
      shopt -s checkwinsize
      function chmodstuff(){
        local typeOf="''${1:-nothing}"
        local topDir="''${2:-nothing}"
        local chmodArgs="''${3:-nothing}"
        if ! [[ "''${#}" -eq 3 ]] || ! [[ "''${1}" =~ (b|d) ]] || ! [[ -d "''${topDir}" ]]
        then
          printf "
No args or bad input.
    Recursively chmods all of \e[1;34mdirectories\e[0m or \e[1;32mfiles\e[0m after path. Remember to quote arg 3.
    \n\nCommand is:
    find \''${2} -type \''${1} -print0 | xargs -0 chmod \''${3}

    For args:
      1. Must be d or f, for directory or file -- Supplied: ''${typeOf}
      2. Must be the path to a directory where you want to run this command -- Supplied: ''${topDir}
      3. Must be quoted args for chmod -- Supplied: ''${chmodArgs}
"
	  return 0
        else
          find "''${2}" -type "''${1}" -print0 | xargs -0 chmod "''${3}"
	  return 1
	fi
      }
      # Provide a nice prompt if the terminal supports it.
      if [ "$TERM" != "dumb" -o -n "$INSIDE_EMACS" ]; then
        PROMPT_COLOR="1;31m"
        let $UID && PROMPT_COLOR="1;32m"
	
        if [ -n "$INSIDE_EMACS" -o "$TERM" == "eterm" -o "$TERM" == "eterm-color" ]; then
          # Emacs term mode doesn't support xterm title escape sequence (\e]0;)
          PS1="\n\[\033[$PROMPT_COLOR\][\u@\h:\w]\\$\[\033[0m\] "
        else
          PS1="\n\[\033[$PROMPT_COLOR\][\[\e]0;\u@\h: \w\a\]\u@\h:\w]\\$\[\033[0m\] "
        fi

        if test "$TERM" = "xterm"; then
          PS1="\[\033]2;\h:\u:\w\007\]$PS1"
        fi
    fi
    '';
  };
}