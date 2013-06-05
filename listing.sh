#!/bin/bash

PWD="`pwd`"
INFO_SH="info.sh"
RMRF_TPL="rm-rf.tpl"
COUNTDOWN=5

CURL=$(which curl)

if [[ ${#CURL} -eq 0 ]]; then
    echo "Install curl first."
    exit 1
fi

INFO=(`$BASH "$PWD/$INFO_SH" -web -ftp`)

if [[ $? -ne 0 ]]; then
    echo "[Error] $PWD/$INFO_SH : ${INFO[@]}"
    exit 1
fi

WEB=${INFO[0]}
FTP=${INFO[1]}

TODO=""

NEW_TODO()
{
    if [[ ${#TODO} -gt 0 ]]; then
        echo "One action at a time." && exit 1
    fi
    TODO=$1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -rm|-rm-rf|--remove-all)
            shift
            NEW_TODO RMRF
            ;;
        *)
            break
            ;;
    esac
done

if [[ $TODO == "RMRF" ]]; then

    for (( i = $COUNTDOWN; i >= 0; i-- )); do
        if [[ $i -ne $COUNTDOWN ]]; then
            printf "\e[1A"
        fi
        echo "Start removing all files on server in ${i} seconds... Ctrl-C to cancel."
        sleep 1
    done
    cat "$PWD/$RMRF_TPL" | \
    $CURL -s -T - "$FTP/htdocs/${RMRF_TPL%\.*}.php"
    $CURL -s -L "$WEB/${RMRF_TPL%\.*}.php"
fi
