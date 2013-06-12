#!/bin/bash
# NET.CN Utils
# https://github.com/caiguanhao/net.cn-utils
# Copyright (c) 2013, Cai Guanhao (Choi Goon-ho) All rights reserved.

PWD="`pwd`"
INFO_SH="info.sh"
MYSQLDUMP_TPL="mysqldump.tpl"
COUNTDOWN=5
COLS=`tput cols`
BOLD=`tput bold`
NORMAL=`tput sgr0`
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

MYSQL="$(which mysql)"

if [[ ${#MYSQL} -eq 0 ]]; then
    echo $"[Error] Install mysql (client) first."
    exit 1
fi

TODO=""
OUTPUT_FILE="-"
VERBOSE=""
SHOWHELP=0

NEW_TODO()
{
    if [[ ${#TODO} -gt 0 ]]; then
        echo $"One database action at a time." && exit 1
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

while [[ $# -gt 0 ]]; do
    case "$1" in
        -b|--backup)
            shift
            NEW_TODO BACKUP
            if [[ $# -gt 0 ]]; then
                OUTPUT_FILE="$1"
                shift
            fi
            ;;
        -d|--drop|--delete)
            shift
            NEW_TODO DROP
            ;;
        -i|--import)
            shift
            NEW_TODO IMPORT
            if [[ $# -gt 0 ]]; then
                SQL_INPUT="$1"
                if [[ ! -f $SQL_INPUT ]]; then
                    echo $"[Error] %s : File does not exist." "$SQL_INPUT"
                    exit 1
                fi
                shift
            fi
            ;;
        -la|-al|--list-all)
            shift
            NEW_TODO LISTALL
            ;;
        -v|--verbose)
            shift
            VERBOSE="-v"
            ;;
        -h|--help)
            shift
            SHOWHELP=1
            ;;
        *)
            break
            ;;
    esac
done

if [[ ${#TODO} -eq 0 ]] || [[ $SHOWHELP -eq 1 ]]; then
    echo $"Usage: %s [OPTIONS...]" "$0"
    echo $"Options:"
    echo $"  -h, --help                   Show this help and exit"
    echo $"  -al, -la, --list-all         List all tables in database"
    echo $"  -b, --backup <file>          Backup database to file"
    echo $"  -d, --drop, --delete         Drop all tables in database"
    echo $"  -i, --import <file>          Import and execute SQL queries"
    echo $"  -v, --verbose                Show more status if possible"
    exit 0
fi

IFS=$'\n'

INFO=($($BASH "$PWD/$INFO_SH" -web -ftp -dbn -dbh -dbu -dbp -pma))

if [[ $? -ne 0 ]]; then
    TEXTDOMAIN=$INFO_SH
    ERROR="`echo "${INFO[*]}"`"
    TEXTDOMAIN=$0
    echo $"[Error] %s : %s" "$PWD/$INFO_SH" "${ERROR}"
    exit 1
fi

WEB="${INFO[0]}"
FTP="${INFO[1]}"
DBN="${INFO[2]}"
DBH="${INFO[3]}"
DBU="${INFO[4]}"
DBP="${INFO[5]}"
PMA="${INFO[6]}"

if [[ $TODO == "LISTALL" ]]; then

    TABLES=(`echo "SHOW TABLES;" | \
        $MYSQL -s -h "${DBH}" -u "${DBU}" -p"${DBP}" "${DBN}" 2>/dev/null`)

    echo $"Database '%s' contains %s tables." "${DBN}" "${#TABLES[@]}"

    [ ${#TABLES[@]} -gt 0 ] && (IFS=$'\n'; echo "${TABLES[*]}")

    exit 0

elif [[ $TODO == "BACKUP" ]]; then

    RAND=$(($RANDOM$RANDOM%99999999+10000000))
    FILE="mysqldump_${RAND}.php"

    cat "$PWD/$MYSQLDUMP_TPL" | \
    sed "s/{{{DBNAME}}}/${DBN}/" | \
    sed "s/{{{HOST}}}/${DBH}/" | \
    sed "s/{{{USER}}}/${DBU}/" | \
    sed "s/{{{PASS}}}/${DBP}/" | \
    $CURL -s ${VERBOSE} -T - "$FTP/htdocs/${FILE}"

    $CURL -s ${VERBOSE} -L "$WEB/$FILE" -o "$OUTPUT_FILE"

    if [[ -s "$OUTPUT_FILE" ]]; then
        echo $"[OK] Your database has been successfully backed up to %s ." "$OUTPUT_FILE"
    else
        echo $"[Error] %s is empty." "$OUTPUT_FILE"
    fi

elif [[ $TODO == "DROP" ]]; then

    TABLES=(`echo "SHOW TABLES;" | \
        $MYSQL -s -h "${DBH}" -u "${DBU}" -p"${DBP}" "${DBN}" 2>/dev/null`)

    if [[ ${#TABLES[@]} -eq 0 ]]; then
        echo $"No tables in the database. Nothing to drop."
        exit 0
    fi

    WARN $"WARNING: ALL DATA IN DATABASE WILL BE REMOVED!"
    WARN $"THIS ACTION IS IRREVERSIBLE. MAKE SURE YOU HAVE IMPORTANT DATA BACKED UP."
    WARN $"%s CONTAINS %s TABLES INCLUDING %s." ${DBN} ${#TABLES[@]} ${TABLES[0]}
    echo
    while [[ $CONFIRM != $DBN ]]; do
        printf "\e[1A"
        echo $"Type %s and press Enter to continue; Ctrl-C to cancel." "${BOLD}${DBN}${NORMAL}"
        read CONFIRM
    done
    for (( i = $COUNTDOWN; i >= 0; i-- )); do
        if [[ $i -ne $COUNTDOWN ]]; then
            printf "\e[1A"
        fi
        echo $"Start dropping tables in %s seconds... Ctrl-C to cancel." "${i}"
        sleep 1
    done

    for (( i = 0; i < ${#TABLES[@]}; i++ )); do
        j=$(( $i + 1 ))
        echo -n $"Dropping table %s %s ... " "${TABLES[$i]}" "[$j/${#TABLES[@]}]"
        echo "DROP TABLE \`${TABLES[$i]}\`;" | \
            $MYSQL -s -h "${DBH}" -u "${DBU}" -p"${DBP}" "${DBN}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            echo $"Done"
        else
            echo $"Fail"
            exit 1
        fi
    done

elif [[ $TODO == "IMPORT" ]]; then

    PMA_INDEX=${PMA%%\?*}

    echo -n $"Logging into phpMyAdmin... "

    IFS=$'\r'

    PMA_RESULT=`$CURL -s ${VERBOSE} -L "${PMA_INDEX}" -X "POST" \
    -b "${PWD}/cookie" \
    -c "${PWD}/cookie" \
    -d "pma_servername=${DBH}" \
    -d "pma_username=${DBU}" \
    -d "pma_password=${DBP}"`

    echo $"Done"

    if [[ ! $PMA_RESULT =~ token=[a-f0-9]{32} ]]; then
        echo $"[Error] %s : Login failed!" "${PMA_INDEX}"
        exit 1
    fi

    TOKEN=${PMA_RESULT%token=*}
    TOKEN=${PMA_RESULT:$(( ${#TOKEN} + 6 )):32}

    PMA_DIR=${PMA_INDEX%/*}

    echo -n $"Sending SQL queries... "

    PMA_IMPORT=`$CURL -s ${VERBOSE} -L "${PMA_DIR}/import.php" -X "POST" \
    -b "${PWD}/cookie" \
    -c "${PWD}/cookie" \
    -d "token=${TOKEN}" \
    --data-urlencode "sql_query@${SQL_INPUT}"`

    echo $"Done"

    if [[ $PMA_IMPORT != *\"notice\"* ]]; then
        echo $"[Exception] Response content does not contain any notices."
        exit
    fi

    DELI='<div class="notice">'
    NOTICE=${PMA_IMPORT%%${DELI}*}
    NOTICE=${PMA_IMPORT:$(( ${#NOTICE} + ${#DELI} ))}
    NOTICE=${NOTICE%%</div>*}

    echo $"phpMyAdmin says: %s." "${NOTICE}"

fi

exit 0
