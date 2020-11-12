
export SLESS_HOME=$SZNPACK_SOURCE_DIR

option=
if [ -t 1 ]; then
    option="$option --color"
fi

declare -a files=()
while [ $# -gt 0 ]; do
    arg="$1"
    if [ "$arg" = -v ]; then
        option="$option -v"
    else
        files+=("$arg")
    fi
    shift
done

if [ -t 1 ]; then
    tput lines >/dev/null 2>&1 && export TERMINAL_LINES=$(tput lines);
    tput cols  >/dev/null 2>&1 && export TERMINAL_COLS=$(tput cols);

    if [ ${#files[@]} = 0 ]; then
        perl $SLESS_HOME/format-wrapper.pl $option "$@" | less -SRX
    elif [ ${#files[@]} = 1 ]; then
        f=${files[0]}
        if [ -d "$f" ]; then
            ls -alF --color=always --time-style="+%Y-%m-%d %H:%M:%S" "$f" | less -SRX
        else
            perl $SLESS_HOME/format-wrapper.pl $option "$@" < "$f" | less -SRX
        fi
    else
        for f in ${files[@]}; do
            echo -e "\e[32m$f\e[m"
            if [ -d "$f" ]; then
                ls -alF --color=always --time-style="+%Y-%m-%d %H:%M:%S" "$f"
            else
                perl $SLESS_HOME/format-wrapper.pl $option "$@" < "$f"
            fi
        done | less -SRX
    fi
else
    if [ ${#files[@]} = 0 ]; then
        perl $SLESS_HOME/format-wrapper.pl $option "$@"
    elif [ ${#files[@]} = 1 ]; then
        f=${files[0]}
        if [ -d "$f" ]; then
            ls -alF --color=never --time-style="+%Y-%m-%d %H:%M:%S" "$f"
        else
            perl $SLESS_HOME/format-wrapper.pl $option "$@" < "$f"
        fi
    else
        for f in ${files[@]}; do
            echo -e "$f"
            if [ -d "$f" ]; then
                ls -alF --color=never --time-style="+%Y-%m-%d %H:%M:%S" "$f"
            else
                perl $SLESS_HOME/format-wrapper.pl $option "$@" < "$f"
            fi
        done
    fi
fi

