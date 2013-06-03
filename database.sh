#!/bin/bash

BASH="/bin/bash"
PWD="`pwd`"
INFO_SH="info.sh"
MYSQLDUMP_TPL="mysqldump.tpl"
COUNTDOWN=5

CURL=$(which curl)

if [[ ${#CURL} -eq 0 ]]; then
    echo "Install curl first."
    exit 1
fi

TODO=""
OUTPUT_FILE="-"
VERBOSE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -b|--backup)
            shift
            if [[ ${#TODO} -gt 0 ]]; then
                echo "One database action at a time." && exit 1
            fi
            TODO="BACKUP"
            ;;
        -o|--output)
            shift
            if [[ $# -gt 0 ]]; then
                OUTPUT_FILE="$1"
                shift
            fi
            ;;
        -d|--drop|--delete)
            shift
            if [[ ${#TODO} -gt 0 ]]; then
                echo "One database action at a time." && exit 1
            fi
            TODO="DROP"
            ;;
        -v|--verbose)
            shift
            VERBOSE="-v"
            ;;
        *)
            break
            ;;
    esac
done

INFO=(`$BASH "$PWD/$INFO_SH" -web -ftp -dbn -dbh -dbu -dbp`)

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

if [[ $TODO == "BACKUP" ]]; then

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

    MYSQL=$(which mysql)

    if [[ ${#MYSQL} -eq 0 ]]; then
        echo "Install mysql (client) first."
        exit 1
    fi

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

fi

exit 0
