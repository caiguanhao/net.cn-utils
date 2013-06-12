#!/bin/bash
# NET.CN Utils
# https://github.com/caiguanhao/net.cn-utils
# Copyright (c) 2013, Cai Guanhao (Choi Goon-ho) All rights reserved.

PWD="`pwd`"
INFO_SH="info.sh"
RMRF_TPL="rm-rf.tpl"
COUNTDOWN=5
COLS=`tput cols`
BOLD=`tput bold`
NORMAL=`tput sgr0`
REMOTE_DIR="/htdocs"
TODO=""
PATHTOLIST="/"
OLDIFS=$IFS

export TEXTDOMAINDIR="${PWD}/locale"
export TEXTDOMAIN="$0"

CURL="$(which curl)"
GETTEXT="$(which gettext)"

echo()
{
    IFS=$OLDIFS
    if [[ ${#@} -eq 0 ]]; then
        printf "\n"
    elif [[ ${#GETTEXT} -eq 0 ]]; then
        if [[ $1 == "-n" ]]; then
            printf "$2" "${@:3}"
        else
            printf "$1\n" "${@:2}"
        fi
    else
        if [[ $1 == "-n" ]]; then
            printf "`${GETTEXT} -s "$2"`" "${@:3}"
        else
            printf "`${GETTEXT} -s "$1"`\n" "${@:2}"
        fi
    fi
}

if [[ ${#CURL} -eq 0 ]]; then
    echo $"[Error] Install curl first."
    exit 1
fi

NEW_TODO()
{
    if [[ ${#TODO} -gt 0 ]]; then
        echo $"One action at a time." && exit 1
    fi
    TODO="$1"
}

GET_WIDTH_OF()
{
    local cwidth=0
    local twidth=0
    for (( i = 0; i < ${#1}; i++ )); do
        cwidth=$(printf "${1:${i}:1}" | wc -c)
        if [[ $cwidth -eq 1 ]]; then
            let "twidth += 1"
        else
            let "twidth = twidth + cwidth - 1"
        fi
    done
    eval "$3=\$twidth"
}

WARN()
{
    WARN_TEXT="`echo "$1" ${@:2}`"
    GET_WIDTH_OF "$WARN_TEXT" TO WARN_TEXT_WIDTH
    printf "\e[1;33;41m"
    FRONT_SPACES=$(( ($COLS - $WARN_TEXT_WIDTH) / 2 ))
    printf "${BOLD}%*s" $FRONT_SPACES
    printf "${WARN_TEXT}"
    printf "%*s" $(( $COLS - $WARN_TEXT_WIDTH - $FRONT_SPACES ))
    printf "${NORMAL}\n"
}

HELP()
{
    echo $"Usage: %s [OPTIONS...]" "$0"
    echo $"Options:"
    echo $"  -h, --help                   Show this help and exit"
    echo $"  -l, --list <path>            List of contents in path"
    echo $"  -rm-rf, --remove-all         Delete everything on server"
    exit 0
}

[ $# -eq 0 ] && HELP

while [[ $# -gt 0 ]]; do
    case "$1" in
        -l|--list)
            shift
            NEW_TODO LIST
            if [[ $# -gt 0 ]]; then
                PATHTOLIST="$1"
                shift
            fi
            ;;
        -rm-rf|--remove-all)
            shift
            NEW_TODO RMRF
            ;;
        *)
            HELP
            break
            ;;
    esac
done

IFS=$'\n'

INFO=($($BASH "$PWD/$INFO_SH" -web -ftp -id -sp))

if [[ $? -ne 0 ]]; then
    TEXTDOMAIN=$INFO_SH
    ERROR="`echo "${INFO[*]}"`"
    TEXTDOMAIN=$0
    echo $"[Error] %s : %s" "$PWD/$INFO_SH" "${ERROR}"
    exit 1
fi

WEB="${INFO[0]}"
FTP="${INFO[1]}"
ID="${INFO[2]}"
SPACE="${INFO[3]}"

if [[ $TODO == "LIST" ]]; then
    if [[ ${PATHTOLIST:0:1} != "/" ]]; then
        PATHTOLIST="/${PATHTOLIST}"
    fi
    if [[ ${PATHTOLIST:(-1)} != "/" ]]; then
        PATHTOLIST="${PATHTOLIST}/"
    fi
    LIST=(`$CURL -w "%{http_code}" -s -l "${FTP}${REMOTE_DIR}${PATHTOLIST}"`)
    STATUS=${LIST[${#LIST[@]}-1]}
    unset LIST[${#LIST[@]}-1]
    FTP_DSP="${FTP}${REMOTE_DIR}${PATHTOLIST}"
    FTP_DSP="ftp://${FTP_DSP##*@}"
    if [[ ${STATUS:0:1} -eq 2 ]]; then
        echo $"%s returned %s items with status code %s." $FTP_DSP ${#LIST[@]} $STATUS
        IFS=$'\n'
        echo "${LIST[*]}"
    else
        echo $"%s returned status code %s." $FTP_DSP $STATUS
    fi
fi

if [[ $TODO == "RMRF" ]]; then

    WARN $"WARNING: ALL FILES AND DIRECTORIES WILL BE REMOVED!"
    WARN $"THIS ACTION IS IRREVERSIBLE. MAKE SURE YOU HAVE IMPORTANT FILES BACKED UP."
    WARN $(echo $"CURRENT SPACE USAGE OF %s: %s." "${ID}" "${SPACE}" | tr '[a-z]' '[A-Z]')
    echo
    while [[ $CONFIRM != $ID ]]; do
        printf "\e[1A"
        echo $"Type %s and press Enter to continue; Ctrl-C to cancel." "${BOLD}${ID}${NORMAL}"
        read CONFIRM
    done
    for (( i = $COUNTDOWN; i >= 0; i-- )); do
        if [[ $i -ne $COUNTDOWN ]]; then
            printf "\e[1A"
        fi
        echo $"Start removing all files on server in %s seconds... Ctrl-C to cancel." "${i}"
        sleep 1
    done
    echo -n $"Uploading self-deleting script... "
    cat "$PWD/$RMRF_TPL" | \
    $CURL -s -T - "${FTP}${REMOTE_DIR}/${RMRF_TPL%\.*}.php"
    echo $"Done"
    echo -n $"Deleting all files... "
    $CURL -s -L "$WEB/${RMRF_TPL%\.*}.php"
    echo $"Done"
    exit 0
fi
