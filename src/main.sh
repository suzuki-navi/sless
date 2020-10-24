
export SLESS_HOME=$SZNPACK_SOURCE_DIR

option=
if [ -t 1 ]; then
    option="$option -c"
fi

if [ -t 1 ]; then
    perl $SLESS_HOME/format-wrapper.pl $option "$@" | less -SRX
else
    perl $SLESS_HOME/format-wrapper.pl $option "$@"
fi

