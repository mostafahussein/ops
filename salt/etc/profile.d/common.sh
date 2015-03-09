alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"


TTY=$(tty)

export HISTTIMEFORMAT="%F %H:%M:%S "
export HISTFILE="${HOME}/.bash_hist-${TTY//\/}"

unset TTY
