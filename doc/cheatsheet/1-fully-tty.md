# Fully TTY

## Linux
```sh
python -c 'import pty; pty.spawn("/bin/bash")'
python3 -c 'import pty; pty.spawn("/bin/bash")'
script /dev/null -qc /bin/bash

(inside the nc session) CTRL+Z;

# stty -a to get rows and cols
stty raw -echo; fg;
clear;export SHELL=/bin/bash;export TERM=xterm-256color;stty rows 60 columns 160;reset

# color-ref: https://ivanitlearning.wordpress.com/2020/03/25/adding-colour-to-linux-tty-shells/
# only works in bash. if facing Garbled, try go into bash 
export LS_OPTIONS='--color=auto'; eval "`dircolors`"; alias ls='ls $LS_OPTIONS'; export PS1='\[\e]0;\u@\h: \w\a\]\[\033[01;32m\]\u@\h\[\033[01;34m\] \w\$\[\033[00m\] '

# If facing garbled, use:
PS1="# "
```