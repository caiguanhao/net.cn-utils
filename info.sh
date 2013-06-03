#!/bin/bash

PWD="`pwd`"

CURL=$(which curl)

USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3)"
USER_AGENT="${USER_AGENT} AppleWebKit/537.31 (KHTML, like Gecko)"
USER_AGENT="${USER_AGENT} Chrome/26.0.1410.65 Safari/537.31"

extract_value_of()
{
    RESULT=${!3%%\"${1}\"*}
    RESULT=${!3:$(( ${#RESULT} + ${#1} + 2 ))}
    _RESULT=${RESULT%%\"*}
    RESULT=${RESULT:$(( ${#_RESULT} + 1 ))}
    RESULT=${RESULT%%\"*}
    eval "${5}=\$RESULT"
}

INFO=`$CURL -s -L "http://cp.hichina.com/AJAXPage.aspx?action=GetIndexInfo" \
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

echo "Info for ${SITEID}:"
echo "  Product Type:             ${TYPENAME}"
echo "  Valid From:               ${OPENDATE}"
echo "  Valid To:                 ${ENDDATE}"
echo "  Status:                   ${STATUS}"
echo "  IP Address:               ${SITEIP}"
echo "  Operating System:         ${OSNAME}"
echo "  Programming Languages:    ${SCRIPTS}"

INFO=`$CURL -s -L "http://cp.hichina.com/AJAXPage.aspx?action=GetWebFtpUrl" \
-b "${PWD}/cookie" \
-c "${PWD}/cookie" \
-A "${USER_AGENT}" | iconv -f gbk`

echo "  FTP Link:                 ${INFO}"

INFO=`$CURL -s -L "http://cp.hichina.com/AJAXPage.aspx?action=GetIndexSpaceDiv" \
-b "${PWD}/cookie" \
-c "${PWD}/cookie" \
-A "${USER_AGENT}" | iconv -f gbk`

echo "  Space Usage:              ${INFO##*&nbsp;}"

INFO=`$CURL -s -L "http://cp.hichina.com/AJAXPage.aspx?action=GetIndexFlowDiv" \
-b "${PWD}/cookie" \
-c "${PWD}/cookie" \
-A "${USER_AGENT}" | iconv -f gbk`

echo "  Bandwidth Usage:          ${INFO##*>}"
