#!/bin/bash

PWD="`pwd`"

CURL=$(which curl)

USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3)"
USER_AGENT="${USER_AGENT} AppleWebKit/537.31 (KHTML, like Gecko)"
USER_AGENT="${USER_AGENT} Chrome/26.0.1410.65 Safari/537.31"

QUERY_URL="http://cp.hichina.com/AJAXPage.aspx"

ARGUMENTS_COUNT=$#

extract_value_of()
{
    RESULT=${!3%%\"${1}\"*}
    RESULT=${!3:$(( ${#RESULT} + ${#1} + 2 ))}
    _RESULT=${RESULT%%\"*}
    RESULT=${RESULT:$(( ${#_RESULT} + 1 ))}
    RESULT=${RESULT%%\"*}
    eval "${5}=\$RESULT"
}

get_value_from()
{
    DELI=$3

    eval "_${1}=\${!1%%\${DELI}*}"
    eval "_${1}=\${!1:\$(( \${#_${1}} + \${#DELI} ))}"

    DELI='value="'

    eval "${1}=\${_PMA%%\${DELI}*}"
    eval "${1}=\${_PMA:\$(( \${#${1}} + \${#DELI} ))}"
}

# Basic Info

INFO=`$CURL -s -L "${QUERY_URL}?action=GetIndexInfo" \
-b "${PWD}/cookie" \
-c "${PWD}/cookie" \
-A "${USER_AGENT}" | iconv -f gbk`

if [[ $INFO != \{*\} ]]; then
    echo "Timeout. You need to log in again."
    exit 1
fi

extract_value_of Opendate   from INFO to OPENDATE
OPENDATE=$(grep -oE "[0-9]{1,}" <<< "$OPENDATE")
OPENDATE=$(date -r "${OPENDATE%000}" "+%Y-%m-%d %H:%M:%S")

extract_value_of Enddate    from INFO to ENDDATE
ENDDATE=$(grep -oE "[0-9]{1,}" <<< "$ENDDATE")
ENDDATE=$(date -r "${ENDDATE%000}" "+%Y-%m-%d %H:%M:%S")

extract_value_of Siteid     from INFO to SITEID

extract_value_of Siteip     from INFO to SITEIP

extract_value_of Typename   from INFO to TYPENAME

extract_value_of Osname     from INFO to OSNAME

extract_value_of Scriptlist from INFO to SCRIPTS

extract_value_of Statusname from INFO to STATUS

if [[ $ARGUMENTS_COUNT -eq 0 ]]; then
    echo "Info for ${SITEID}:"
    echo "  Product Type:             ${TYPENAME}"
    echo "  Valid From:               ${OPENDATE}"
    echo "  Valid To:                 ${ENDDATE}"
    echo "  Status:                   ${STATUS}"
    echo "  IP Address:               ${SITEIP}"
    echo "  Operating System:         ${OSNAME}"
    echo "  Programming Languages:    ${SCRIPTS}"
fi

# FTP Link

FTPLINK=`$CURL -s -L "${QUERY_URL}?action=GetWebFtpUrl" \
-b "${PWD}/cookie" \
-c "${PWD}/cookie" \
-A "${USER_AGENT}" | iconv -f gbk`

if [[ $ARGUMENTS_COUNT -eq 0 ]]; then
    echo "  FTP Link:                 ${FTPLINK}"
fi

# Space Usage

INFO=`$CURL -s -L "${QUERY_URL}?action=GetIndexSpaceDiv" \
-b "${PWD}/cookie" \
-c "${PWD}/cookie" \
-A "${USER_AGENT}" | iconv -f gbk`
SPACEUSED=${INFO##*&nbsp;}

if [[ $ARGUMENTS_COUNT -eq 0 ]]; then
    echo "  Space Usage:              ${SPACEUSED}"
fi

# Bandwidth Usage

INFO=`$CURL -s -L "${QUERY_URL}?action=GetIndexFlowDiv" \
-b "${PWD}/cookie" \
-c "${PWD}/cookie" \
-A "${USER_AGENT}" | iconv -f gbk`
BWUSED=${INFO##*>}

if [[ $ARGUMENTS_COUNT -eq 0 ]]; then
    echo "  Bandwidth Usage:          ${BWUSED}"
fi

# Database Name and PhpMyAdmin URL

INFO=`$CURL -s -L "${QUERY_URL}?action=GetDBList" \
-b "${PWD}/cookie" \
-c "${PWD}/cookie" \
-A "${USER_AGENT}" | iconv -f gbk`

DELI="<td class='bian5'>"

_INFO=${INFO%%${DELI}*}
_INFO=${INFO:$(( ${#_INFO} + ${#DELI} ))}

DBNAME=${_INFO%%<*}

INFO=${_INFO%%${DELI}*}
_INFO=${_INFO:$(( ${#INFO} + ${#DELI} ))}

DELI="href='"

INFO=${_INFO%%${DELI}*}
_INFO=${_INFO:$(( ${#INFO} + ${#DELI} ))}

DBLINK=${_INFO%%\'*}

if [[ $ARGUMENTS_COUNT -eq 0 ]]; then
    echo "  PhpMyAdmin Link:          ${DBLINK}"
    echo "  Database Name:            ${DBNAME}"
fi

# Database Server, User Name, Password

IFS=$'\r'

PMA=`$CURL -s -L "${DBLINK}" \
-b "${PWD}/cookie" \
-c "${PWD}/cookie" \
-A "${USER_AGENT}"`

get_value_from PMA starting_from 'id="input_servername"'
DBSERVER=${PMA%%\"*}

get_value_from PMA starting_from 'id="input_username"'
DBUSER=${PMA%%\"*}

get_value_from PMA starting_from 'id="input_password"'
DBPASS=${PMA%%\"*}

if [[ $ARGUMENTS_COUNT -eq 0 ]]; then
    echo "  Database Server:          ${DBSERVER}"
    echo "  Database User Name:       ${DBUSER}"
    echo "  Database Password:        ${DBPASS}"
fi
