#!/bin/bash

CURL=$(which curl)
PWD="`pwd`"
INFO_SH="info.sh"
REMOTE_DIR="/htdocs"
ZIP=$(which zip)

if [[ ${#CURL} -eq 0 ]]; then
    echo "Install curl first."
    exit 1
fi

if [[ ${#ZIP} -eq 0 ]]; then
    echo "Install zip first."
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--from)
            shift
            if [[ $# -gt 0 ]]; then
                FROM="$1"
                if [[ ! -e $FROM ]]; then
                    echo "[Error] $FROM : No such file or directory."
                    exit 1
                fi
                shift
            fi
            ;;
        -t|--to)
            shift
            if [[ $# -gt 0 ]]; then
                TO="$1"
                shift
            fi
            ;;
        *)
            break
            ;;
    esac
done

INFO=(`$BASH "$PWD/$INFO_SH" -ftp`)

if [[ $? -ne 0 ]]; then
    echo "[Error] $PWD/$INFO_SH : ${INFO[@]}"
    exit 1
fi

FTP="${INFO[0]}${REMOTE_DIR}"

TMP_FILE=""
if [[ -d $FROM ]]; then
    TMP_FILE=$(($RANDOM$RANDOM%99999999+10000000))
    TMP_FILE="/tmp/$TMP_FILE.zip"
    echo "$FROM will be compressed as ZIP file. [Enter]: Yes; [Ctrl-C]: No."
    echo $ZIP -9 -q -r "${TMP_FILE}" "$FROM"
    read
    $ZIP -9 -q -r "${TMP_FILE}" "$FROM" || exit 1
    FROM=$TMP_FILE
fi

if [[ ${TO:0:${#REMOTE_DIR}} == ${REMOTE_DIR} ]]; then
    TO=${TO:${#REMOTE_DIR}}
fi
if [[ ${#TO} -gt 0 ]]; then
    if [[ ${FROM##*\.} != ${TO##*\.} ]]; then
        if [[ ${TO:(-1)} != "/" ]]; then
            TO="${TO}/"
        fi
        TO="${TO}${FROM##*/}"
    fi
fi
if [[ ${TO:0:1} != "/" ]]; then
    TO="/${TO}"
fi

echo "Is this command OK? [Enter]: Yes; [Ctrl-C]: No."
echo -n $CURL --ftp-create-dirs -T "${FROM}" "${FTP}${TO}"
read

$CURL --ftp-create-dirs -T "${FROM}" "${FTP}${TO}"

if [[ ${#TMP_FILE} -gt 0 ]]; then
    rm -f "${TMP_FILE}"
fi
