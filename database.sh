#!/bin/bash

PWD="`pwd`"
INFO_SH="info.sh"
MYSQLDUMP_TPL="mysqldump.tpl"
COUNTDOWN=5

CURL=$(which curl)

if [[ ${#CURL} -eq 0 ]]; then
    echo "Install curl first."
    exit 1
fi

MYSQL=$(which mysql)

if [[ ${#MYSQL} -eq 0 ]]; then
    echo "Install mysql (client) first."
    exit 1
fi

TODO=""
OUTPUT_FILE="-"
VERBOSE=""
SHOWHELP=0

NEW_TODO()
{
    if [[ ${#TODO} -gt 0 ]]; then
        echo "One database action at a time." && exit 1
    fi
    TODO=$1
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
                    echo "[Error] $SQL_INPUT : File does not exist."
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
    echo "Usage: database.sh [OPTIONS...]"
    echo "Options:"
    echo "  -h, --help              Show this help and exit"
    echo "  -al, -la, --list-all    List all tables in database"
    echo "  -b, --backup <file>     Backup database to file"
    echo "  -d, --drop, --delete    Drop all tables in database"
    echo "  -i, --import <file>     Import and execute SQL queries"
    echo "  -v, --verbose           Show more status if possible"
    exit 0
fi

INFO=(`$BASH "$PWD/$INFO_SH" -web -ftp -dbn -dbh -dbu -dbp -pma`)

if [[ $? -ne 0 ]]; then
    echo "[Error] $PWD/$INFO_SH : ${INFO[@]}"
    exit 1
fi

WEB=${INFO[0]}
FTP=${INFO[1]}
DBN=${INFO[2]}
DBH=${INFO[3]}
DBU=${INFO[4]}
DBP=${INFO[5]}
PMA=${INFO[6]}

if [[ $TODO == "LISTALL" ]]; then

    TABLES=(`echo "SHOW TABLES;" | \
        $MYSQL -s -h "${DBH}" -u "${DBU}" -p"${DBP}" "${DBN}" 2>/dev/null`)

    echo "Database '${DBN}' contains ${#TABLES[@]} tables."

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

elif [[ $TODO == "DROP" ]]; then

    TABLES=(`echo "SHOW TABLES;" | \
        $MYSQL -s -h "${DBH}" -u "${DBU}" -p"${DBP}" "${DBN}" 2>/dev/null`)

    if [[ ${#TABLES[@]} -eq 0 ]]; then
        echo "No tables in the database. Nothing to drop."
        exit 0
    fi

    echo "Found ${#TABLES[@]} tables."

    for (( i = $COUNTDOWN; i >= 0; i-- )); do
        if [[ $i -ne $COUNTDOWN ]]; then
            printf "\e[1A"
        fi
        echo "Start dropping tables in ${i} seconds... Ctrl-C to cancel."
        sleep 1
    done

    for (( i = 0; i < ${#TABLES[@]}; i++ )); do
        j=$(( $i + 1 ))
        echo -n "Dropping table ${TABLES[$i]} [$j/${#TABLES[@]}] ... "
        echo "DROP TABLE \`${TABLES[$i]}\`;" | \
            $MYSQL -s -h "${DBH}" -u "${DBU}" -p"${DBP}" "${DBN}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            echo "Done"
        else
            echo "Fail"
            exit 1
        fi
    done

elif [[ $TODO == "IMPORT" ]]; then

    PMA_INDEX=${PMA%%\?*}

    echo -n "Logging into phpMyAdmin... "

    IFS=$'\r'

    PMA_RESULT=`$CURL -s ${VERBOSE} -L "${PMA_INDEX}" -X "POST" \
    -b "${PWD}/cookie" \
    -c "${PWD}/cookie" \
    -d "pma_servername=${DBH}" \
    -d "pma_username=${DBU}" \
    -d "pma_password=${DBP}"`

    echo "Done"

    if [[ ! $PMA_RESULT =~ token=[a-f0-9]{32} ]]; then
        echo "[Error] ${PMA_INDEX} : Login failed!"
        exit 1
    fi

    TOKEN=${PMA_RESULT%token=*}
    TOKEN=${PMA_RESULT:$(( ${#TOKEN} + 6 )):32}

    PMA_DIR=${PMA_INDEX%/*}

    echo -n "Sending SQL queries... "

    PMA_IMPORT=`$CURL -s ${VERBOSE} -L "${PMA_DIR}/import.php" -X "POST" \
    -b "${PWD}/cookie" \
    -c "${PWD}/cookie" \
    -d "token=${TOKEN}" \
    --data-urlencode "sql_query@${SQL_INPUT}"`

    echo "Done"

    if [[ $PMA_IMPORT != *\"notice\"* ]]; then
        echo "[Exception] Response content does not contain any notices."
        exit
    fi

    DELI='<div class="notice">'
    NOTICE=${PMA_IMPORT%%${DELI}*}
    NOTICE=${PMA_IMPORT:$(( ${#NOTICE} + ${#DELI} ))}
    NOTICE=${NOTICE%%</div>*}

    echo "phpMyAdmin says: ${NOTICE}."

fi

exit 0
