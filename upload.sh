#!/bin/bash

CURL=$(which curl)
PWD="`pwd`"
INFO_SH="info.sh"
REMOTE_DIR="/htdocs"
ZIP=$(which zip)
EXTRACT=0
COLS=`tput cols`
BOLD=`tput bold`
NORMAL=`tput sgr0`
INTERACTIVE=1
OVERWRITE=1
KEEPARCHIVE=0

if [[ ${#CURL} -eq 0 ]]; then
    echo "Install curl first."
    exit 1
fi

if [[ ${#ZIP} -eq 0 ]]; then
    echo "Install zip first."
    exit 1
fi

QUERY_URL="http://cp.hichina.com/AJAXPage.aspx"

USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) \
AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.65 Safari/537.31"

HELP()
{
    echo "Usage: $0 [OPTIONS...]"
    echo "Options:"
    echo "  -h, --help                   Show this help and exit"
    echo "  -f, -from <file>             File to upload, directory will be 
                               compressed as zip file"
    echo "  -t, --to <path>              Remote path relative to ${REMOTE_DIR}"
    echo "  -e, --extract <file.zip>     Remote zip file to extract"
    echo "  -d, --destination <path>     Extract files to path"
    echo "  -s, --no-overwrite           Do not overwrite existing files"
    echo "  -k, --keep-archive           Do not delete the archive file"
    echo "  -y, --assumeyes, -n, --non-interactive"
    echo "                               Execute commands without confirmations"
    exit 0
}

INFORM()
{
    printf "\e[1;33;42m"
    FRONT_SPACES=$(( ($COLS - ${#1}) / 2 ))
    printf "${BOLD}%*s" $FRONT_SPACES
    printf "${1}"
    printf "%*s" $(( $COLS - ${#1} - $FRONT_SPACES ))
    printf "${NORMAL}\n"
}

[ $# -eq 0 ] && HELP

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
            if [[ $# -gt 0 ]]; then
                if [[ ${1##*\.} == "zip" ]]; then
                    EXTRACT_SRC="$1"
                    shift
                else
                    echo "[Error] -e, --extract:"
                    echo "[Error] You must specify the name of remote zip file."
                    echo "[Error] Remove this option if you want to extract"
                    echo "[Error] the zip file that will be uploaded."
                    exit 1
                fi
            fi
            ;;
        -d|--destination)
            shift
            EXTRACT=1
            if [[ $# -gt 0 ]]; then
                EXTRACT_DST="$1"
                shift
            fi
            ;;
        -s|--no-overwrite)
            shift
            OVERWRITE=0
            ;;
        -k|--keep-archive)
            shift
            KEEPARCHIVE=1
            ;;
        -y|--assumeyes|-n|--non-interactive)
            shift
            INTERACTIVE=0
            ;;
        *)
            HELP
            break
            ;;
    esac
done

INFO=(`$BASH "$PWD/$INFO_SH" -ftp`)

if [[ $? -ne 0 ]]; then
    echo "[Error] $PWD/$INFO_SH : ${INFO[@]}"
    exit 1
fi

FTP="${INFO[0]}"

if [[ ${#FROM} -gt 0 ]]; then
    TMP_FILE=""
    if [[ -d $FROM ]]; then
        INFORM "CREATING ARCHIVE"
        TMP_FILE=$(($RANDOM$RANDOM%99999999+10000000))
        TMP_FILE="/tmp/$TMP_FILE.zip"
        echo $BOLD $ $ZIP -9 -q -r "${TMP_FILE}" "$FROM"$NORMAL "[Enter/Ctrl-C] ?"
        [ $INTERACTIVE -eq 1 ] && read
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

    INFORM "UPLOADING FILE"

    echo -n $BOLD $ $CURL --ftp-create-dirs -T "${FROM} "
    echo "${FTP}${REMOTE_DIR}${TO}"$NORMAL "[Enter/Ctrl-C] ?"
    [ $INTERACTIVE -eq 1 ] && read

    $CURL --ftp-create-dirs -T "${FROM}" "${FTP}${REMOTE_DIR}${TO}"

    if [[ ${#TMP_FILE} -gt 0 ]]; then
        rm -f "${TMP_FILE}"
    fi

    echo
fi

if [[ $EXTRACT -eq 1 ]]; then

    if [[ ${#EXTRACT_SRC} -eq 0 ]]; then
        EXTRACT_SRC=${TO}
    fi
    if [[ ${#EXTRACT_SRC} -eq 0 ]]; then
        echo "[Error] Fail to extract file: no input file."
        exit 1
    fi
    if [[ ${EXTRACT_SRC:0:1} != "/" ]]; then
        EXTRACT_SRC="/${EXTRACT_SRC}"
    fi
    if [[ ${EXTRACT_DST:0:1} != "/" ]]; then
        EXTRACT_DST="/${EXTRACT_DST}"
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

    INFORM "EXTRACTING ARCHIVE"

    echo $BOLD $ $CURL -s -G "${QUERY_URL}" \
    -d "action=uncommpressfilesold" \
    -d "serverfilename=${EXTRACT_SRC}" \
    -d "serverdir=${EXTRACT_DST}" \
    -d "iscover=${OVERWRITE}" ...$NORMAL "[Enter/Ctrl-C] ?"
    [ $INTERACTIVE -eq 1 ] && read

    OUTPUT=`$CURL -s -G "${QUERY_URL}" \
    -d "action=uncommpressfilesold" \
    -d "serverfilename=${EXTRACT_SRC}" \
    -d "serverdir=${EXTRACT_DST}" \
    -d "iscover=${OVERWRITE}" \
    -b "${PWD}/cookie" \
    -c "${PWD}/cookie" \
    -A "${USER_AGENT}" | iconv -f gbk`

    if [[ $OUTPUT == *200\|OK* ]]; then
        echo "[OK] File has been successfully extracted."
    else
        echo "[Error] Fail to extract file. Message: $OUTPUT"
        exit 1
    fi

    if [[ $KEEPARCHIVE -ne 1 ]]; then
        INFORM "DELETING ARCHIVE"

        echo $BOLD $ $CURL -s "${FTP}" \
        -X "DELE ${REMOTE_DIR}${EXTRACT_SRC}" $NORMAL "[Enter/Ctrl-C] ?"
        [ $INTERACTIVE -eq 1 ] && read

        echo -n "Deleting ${REMOTE_DIR}${EXTRACT_SRC} ... "
        OUTPUT=`$CURL -s "${FTP}" -X "DELE ${REMOTE_DIR}${EXTRACT_SRC}" \
        -w "%{http_code}" -o /dev/null`
        echo "Done"

        if [[ $OUTPUT -eq 250 ]]; then
            echo "[OK] File has been deleted."
        else
            echo "[Exception] Exit with FTP return code $OUTPUT (should be 250)."
            exit 1
        fi
    fi
fi
