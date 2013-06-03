#!/bin/bash

BASH="/bin/bash"
PWD="`pwd`"
INFO_SH="$PWD/info.sh"
MYSQLDUMP_TPL="mysqldump.tpl"

CURL=$(which curl)

if [[ ${#CURL} -eq 0 ]]; then
    echo "Install curl first."
    exit 1
fi

INFO=(`$BASH "$INFO_SH" -web -ftp -dbn -dbh -dbu -dbp`)

if [[ $? -ne 0 ]]; then
	echo "[Error] $INFO_SH : ${INFO[@]}"
	exit 1
fi

WEB=${INFO[0]}
FTP=${INFO[1]}
DBN=${INFO[2]}
DBH=${INFO[3]}
DBU=${INFO[4]}
DBP=${INFO[5]}

RAND=$(($RANDOM$RANDOM%99999999+10000000))
FILE="mysqldump_${RAND}.php"

cat "$PWD/$MYSQLDUMP_TPL" | \
sed "s/{{{DBNAME}}}/${DBN}/" | \
sed "s/{{{HOST}}}/${DBH}/" | \
sed "s/{{{USER}}}/${DBU}/" | \
sed "s/{{{PASS}}}/${DBP}/" | \
$CURL -s -T - "$FTP/htdocs/${FILE}"

$CURL -s -L "$WEB/$FILE"
