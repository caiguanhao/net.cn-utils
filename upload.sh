#!/bin/bash

CURL=$(which curl)
PWD="`pwd`"
INFO_SH="info.sh"
REMOTE_DIR="/htdocs"
ZIP=$(which zip)
EXTRACT=0

if [[ ${#CURL} -eq 0 ]]; then
    echo "Install curl first."
    exit 1
fi

if [[ ${#ZIP} -eq 0 ]]; then
    echo "Install zip first."
    exit 1
fi

QUERY_URL="http://cp.hichina.com/AJAXPage.aspx"

USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3)"
USER_AGENT="${USER_AGENT} AppleWebKit/537.31 (KHTML, like Gecko)"
USER_AGENT="${USER_AGENT} Chrome/26.0.1410.65 Safari/537.31"

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
        -e|--extract)
            shift
            EXTRACT=1
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
else
    TO=${FROM##*/}
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

if [[ $EXTRACT -eq 1 ]]; then

    if [[ ${#TO} -eq 0 ]]; then
        echo "[Error] Fail to extract file: no input file."
        exit 1
    fi

    OUTPUT=`$CURL -s -G "http://cp.hichina.com/FileUncompressionold.aspx" \
    -d "tr=fileuncompressionold" \
    -b "${PWD}/cookie" \
    -c "${PWD}/cookie" \
    -A "${USER_AGENT}" \
    -o /dev/null \
    -w "%{http_code}"`

    if [[ $OUTPUT -ne 200 ]]; then
        echo "[Exception] Exit with status code ${OUTPUT} (should be 200)."
        if [[ $OUTPUT -eq 302 ]]; then
            echo "[Exception] You may need to log in again."
        fi
        exit 1
    fi

    echo "${TO} will be extracted to / . Enter to continue. Ctrl-C tp cancel."
    read

    OUTPUT=`$CURL -s -G "${QUERY_URL}" \
    -d "action=uncommpressfilesold" \
    -d "serverfilename=${TO}" \
    -d "serverdir=/" \
    -d "iscover=1" \
    -b "${PWD}/cookie" \
    -c "${PWD}/cookie" \
    -A "${USER_AGENT}" | iconv -f gbk`

    if [[ $OUTPUT == *200\|OK* ]]; then
        echo "[OK] File has been successfully extracted."
    else
        echo "[Error] Fail to extract file. Message: $OUTPUT"
        exit 1
    fi

fi
