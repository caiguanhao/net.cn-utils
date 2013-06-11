#!/bin/bash

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

CURL=$(which curl)

if [[ ${#CURL} -eq 0 ]]; then
    echo $"[Error] Install curl first."
    exit 1
fi

NEW_TODO()
{
    if [[ ${#TODO} -gt 0 ]]; then
        echo $"One action at a time." && exit 1
    fi
    TODO=$1
}

WARN()
{
    printf "\e[1;33;41m"
    FRONT_SPACES=$(( ($COLS - ${#1}) / 2 ))
    printf "${BOLD}%*s" $FRONT_SPACES
    printf "${1}"
    printf "%*s" $(( $COLS - ${#1} - $FRONT_SPACES ))
    printf "${NORMAL}\n"
}

HELP()
{
    echo $"Usage: $0 [OPTIONS...]"
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

INFO=(`$BASH "$PWD/$INFO_SH" -web -ftp -id -sp`)

if [[ $? -ne 0 ]]; then
    echo $"[Error] $PWD/$INFO_SH : ${INFO[@]}"
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
        echo $"$FTP_DSP returned ${#LIST[@]} items with status code $STATUS."
        IFS=$'\n'
        echo "${LIST[*]}"
    else
        echo $"$FTP_DSP returned status code $STATUS."
    fi
fi

if [[ $TODO == "RMRF" ]]; then

    WARN $"WARNING: ALL FILES AND DIRECTORIES WILL BE REMOVED!"
    WARN $"THIS ACTION IS IRREVERSIBLE. MAKE SURE YOU HAVE IMPORTANT FILES BACKED UP."
    WARN $(echo $"CURRENT SPACE USAGE OF ${ID}: ${SPACE}." | tr '[a-z]' '[A-Z]')
    echo
    while [[ $CONFIRM != $ID ]]; do
        printf "\e[1A"
        echo $"Type ${ID} and press Enter to continue; Ctrl-C to cancel."
        read CONFIRM
    done
    for (( i = $COUNTDOWN; i >= 0; i-- )); do
        if [[ $i -ne $COUNTDOWN ]]; then
            printf "\e[1A"
        fi
        echo $"Start removing all files on server in ${i} seconds... Ctrl-C to cancel."
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
