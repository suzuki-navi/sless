
export SLESS_HOME=$SZNPACK_SOURCE_DIR

option=
if [ -t 1 ]; then
    option="$option --color"
fi

if [ -t 1 ]; then
    tput lines >/dev/null 2>&1 && export TERMINAL_LINES=$(tput lines);
    tput cols  >/dev/null 2>&1 && export TERMINAL_COLS=$(tput cols);

    perl $SLESS_HOME/format-wrapper.pl $option "$@" | less -SRX
else
    perl $SLESS_HOME/format-wrapper.pl $option "$@"
fi

