#!/bin/bash

PWD="`pwd`"

CURL=$(which curl)

if [[ ${#CURL} -eq 0 ]]; then
    echo "Install curl first."
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: login.sh [OPTIONS...]"
            echo "Options:"
            echo "  -h, --help          Show this help and exit"
            echo "  -u, --username      Log in with this user name"
            echo "  -p, --password      Log in with this password"
            exit 0
            ;;
        -u|--username)
            shift
            if [[ $# -gt 0 ]]; then
                USERNAME=$1
                shift
            fi
            ;;
        -p|--password)
            shift
            if [[ $# -gt 0 ]]; then
                PASSWORD=$1
                shift
            fi
            ;;
        *)
            break
            ;;
    esac
done

if [[ ${#USERNAME} -eq 0 ]]; then
    echo -n "User name (hmu*): "
    read USERNAME
fi

if [[ ${#PASSWORD} -eq 0 ]]; then
    echo -n "Password for ${USERNAME}: "
    read PASSWORD
fi

USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3)"
USER_AGENT="${USER_AGENT} AppleWebKit/537.31 (KHTML, like Gecko)"
USER_AGENT="${USER_AGENT} Chrome/26.0.1410.65 Safari/537.31"

rm -f "${PWD}/cookie"

IFS=$'\r'

HEADER=`$CURL -I -s -L "http://cp.hichina.com/CheckCode.aspx" \
-b "${PWD}/cookie" \
-c "${PWD}/cookie" \
-A "${USER_AGENT}"`

CHECKCODE_POS=${HEADER%%CheckCode=*}
CHECKCODE_POS=$(( ${#CHECKCODE_POS} + 10 ))

CHECKCODE=${HEADER:$CHECKCODE_POS}
CHECKCODE_POS=${CHECKCODE%%;*}

CHECKCODE=${CHECKCODE:0:${#CHECKCODE_POS}}

if [[ ${#CHECKCODE} -eq 0 ]]; then
    echo "No verification code."
    exit 1
fi

LOGIN_PAGE=`$CURL -s -L "http://cp.hichina.com/" \
-b "${PWD}/cookie" \
-c "${PWD}/cookie" \
-A "${USER_AGENT}" | iconv -f gbk`

VIEWSTATE=${LOGIN_PAGE%%name=\"__VIEWSTATE\"*}
VIEWSTATE=${LOGIN_PAGE:${#VIEWSTATE}}

__VIEWSTATE=${VIEWSTATE%%value=\"*}
__VIEWSTATE=$(( ${#__VIEWSTATE} + 7 ))
__VIEWSTATE=${VIEWSTATE:${__VIEWSTATE}}
__VIEWSTATE=${__VIEWSTATE%%\"*}

EVENTVALIDATION=${LOGIN_PAGE%%name=\"__EVENTVALIDATION\"*}
EVENTVALIDATION=${LOGIN_PAGE:${#EVENTVALIDATION}}

__EVENTVALIDATION=${EVENTVALIDATION%%value=\"*}
__EVENTVALIDATION=$(( ${#__EVENTVALIDATION} + 7 ))
__EVENTVALIDATION=${EVENTVALIDATION:${__EVENTVALIDATION}}
__EVENTVALIDATION=${__EVENTVALIDATION%%\"*}
__EVENTVALIDATION="${__EVENTVALIDATION}"

OUTPUT=`$CURL -s "http://cp.hichina.com/login.aspx" \
-e "http://cp.hichina.com/" \
-b "${PWD}/cookie" \
-c "${PWD}/cookie" \
-A "${USER_AGENT}" \
-X "POST" \
-w "%{http_code}" \
-o /dev/null \
--data-urlencode "__EVENTTARGET=" \
--data-urlencode "__EVENTARGUMENT=" \
--data-urlencode "__LASTFOCUS=" \
--data-urlencode "__VIEWSTATE=${__VIEWSTATE}" \
--data-urlencode "__EVENTVALIDATION=${__EVENTVALIDATION}" \
--data-urlencode "RBLSelectLogin=1" \
--data-urlencode "txtName=${USERNAME}" \
--data-urlencode "txtPassword=${PASSWORD}" \
--data-urlencode "txtImgVerifyCode=${CHECKCODE}" \
--data-urlencode "btnSubmit.x=64" \
--data-urlencode "btnSubmit.y=8"`

if [[ ! $OUTPUT -eq 302 ]]; then
    echo "Exit with status code ${OUTPUT} (should be 302)."
    exit 1
fi

OUTPUT=`$CURL -s "http://cp.hichina.com/index.aspx" \
-e "http://cp.hichina.com/" \
-b "${PWD}/cookie" \
-c "${PWD}/cookie" \
-A "${USER_AGENT}" | iconv -f gbk`

if [[ ! $OUTPUT == *退出* ]]; then
    echo "It seems you are not logged in."
    exit 1
fi

echo "You are logged in."
