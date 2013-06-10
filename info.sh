#!/bin/bash

PWD="`pwd`"
COOKIE="${PWD}/cookie"

CURL=$(which curl)

if [[ ${#CURL} -eq 0 ]]; then
    echo "Install curl first."
    exit 1
fi

USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) \
AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.65 Safari/537.31"

QUERY_URL="http://cp.hichina.com/AJAXPage.aspx"

NEED_LOGIN_AGIAN="Timeout. You need to log in again."

ARGUMENTS_COUNT=$#

ARGUMENTS=()

PART1=0
PART1_VAR=(     TYPENAME        OPENDATE        ENDDATE         STATUS
                SITEIP          OSNAME          SCRIPTS         WEBLINK
                SITEID          WEBLINKS                                    )
PART1_SHORT=(   -t              -vf             -vt             -s
                -ip             -os             -l              -web
                -id             -webs                                       )
PART1_LONG=(    --type          --valid-from    --valid-to      --status
                --ip-address    --system        --languages     --web-link
                --site-id       --web-links                                 )

PART2=0
PART2_VAR=(     FTPLINK         FTPMIRROR                                   )
PART2_SHORT=(   -ftp            -cftp                                       )
PART2_LONG=(    --ftp-link      --ftp-mirror                                )

PART3=0
PART3_VAR=(     SPACEUSED                                                   )
PART3_SHORT=(   -sp                                                         )
PART3_LONG=(    --space-usage                                               )

PART4=0
PART4_VAR=(     BWUSED                                                      )
PART4_SHORT=(   -bw                                                         )
PART4_LONG=(    --bandwidth-usage                                           )

PART5=0
PART5_VAR=(     DBLINK                          DBNAME                      )
PART5_SHORT=(   -pma                            -dbn                        )
PART5_LONG=(    --phpmyadmin-link               --database-name             )

PART6=0
PART6_VAR=(     DBHOST                          DBUSER
                DBPASS                          MYSQLDUMP
                MYSQLCONNECT                                                )
PART6_SHORT=(   -dbh                            -dbu
                -dbp                            -csql
                -cmysql                                                     )
PART6_LONG=(    --database-host                 --database-username
                --database-password             --mysqldump
                --mysql-connect                                             )

PART7=0
PART7_VAR=(     SETCOOKIE                                                   )
PART7_SHORT=(   -c                                                          )
PART7_LONG=(    --cookie                                                    )

SHOWHELP=0

for (( i = 1; i <= $#; i++ )); do
    for (( j = 1; j <= 7; j++ )); do
        SHORT="PART${j}_SHORT[@]"
        SHORT=(${!SHORT})
        LONG="PART${j}_LONG[@]"
        LONG=(${!LONG})
        for (( k = 0; k < ${#SHORT[@]}; k++ )); do
            if [[ ${SHORT[$k]} == ${@:$i:1} ]] || 
               [[ ${LONG[$k]} == ${@:$i:1} ]]; then
                eval "ARGUMENTS=(\${ARGUMENTS[@]} \${PART${j}_VAR[$k]})"
                eval "PART${j}=1"
            fi
        done
    done
    if [[ ${@:$i:1} == "-h" ]] || [[ ${@:$i:1} == "--help" ]]; then
        SHOWHELP=1
    fi
done

if [[ $SHOWHELP -eq 1 ]]; then
    ARGUMENTS=()
fi

date -r 0 >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
    DATE_TYPE=0
else
    date -d "@0" >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        DATE_TYPE=1
    else
        DATE_TYPE=2
    fi
fi

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

if [[ $ARGUMENTS_COUNT -eq 0 ]] || [[ $PART1 -eq 1 ]]; then

    INFO=`$CURL -s -L "${QUERY_URL}?action=GetIndexInfo" \
    -b "${COOKIE}" \
    -c "${COOKIE}" \
    -A "${USER_AGENT}" | iconv -f gbk`

    if [[ $INFO != \{*\} ]]; then
        echo $NEED_LOGIN_AGIAN
        exit 1
    fi

    extract_value_of Opendate   from INFO to OPENDATE
    OPENDATE=$(grep -oE "[0-9]{1,}" <<< "$OPENDATE")

    extract_value_of Enddate    from INFO to ENDDATE
    ENDDATE=$(grep -oE "[0-9]{1,}" <<< "$ENDDATE")

    case $DATE_TYPE in
        0)
            OPENDATE=$(date -r "${OPENDATE%000}" "+%Y-%m-%d %H:%M:%S")
            ENDDATE=$(date -r "${ENDDATE%000}" "+%Y-%m-%d %H:%M:%S")
            ;;
        1)
            OPENDATE=$(date -d "@${OPENDATE%000}" "+%Y-%m-%d %H:%M:%S")
            ENDDATE=$(date -d "@${ENDDATE%000}" "+%Y-%m-%d %H:%M:%S")
            ;;
    esac

    extract_value_of Siteid     from INFO to SITEID

    extract_value_of Siteip     from INFO to SITEIP

    extract_value_of Typename   from INFO to TYPENAME

    extract_value_of Osname     from INFO to OSNAME

    extract_value_of Scriptlist from INFO to SCRIPTS

    extract_value_of Statusname from INFO to STATUS

    if [[ $STATUS == "运行" ]]; then
        STATUS="Running"
    fi

    IFS=$'\r'
    INFO=`$CURL -s -L "${QUERY_URL}?action=GetDomainBindList" \
    -b "${COOKIE}" \
    -c "${COOKIE}" \
    -A "${USER_AGENT}" | iconv -f gbk`
    INFO=${INFO##*|}
    INFO="http://${INFO//,/, http://}"
    WEBLINK="${INFO%%,*}"
    WEBLINKS="${INFO}"

    if [[ $PART1 -eq 0 ]]; then
        echo "Info for ${SITEID}:"
        echo "  Product Type:             ${TYPENAME}"
        echo "  Valid From:               ${OPENDATE}"
        echo "  Valid To:                 ${ENDDATE}"
        echo "  Status:                   ${STATUS}"
        echo "  IP Address:               ${SITEIP}"
        echo "  Operating System:         ${OSNAME}"
        echo "  Programming Languages:    ${SCRIPTS}"
        echo "  Web Link:                 ${WEBLINK}"
        echo "  Web Links:                ${WEBLINKS}"
    fi
fi

# FTP Link

if [[ $ARGUMENTS_COUNT -eq 0 ]] || [[ $PART2 -eq 1 ]]; then

    FTPLINK=`$CURL -s -L "${QUERY_URL}?action=GetWebFtpUrl" \
    -b "${COOKIE}" \
    -c "${COOKIE}" \
    -A "${USER_AGENT}" | iconv -f gbk`

    if [[ ${#FTPLINK} -eq 0 ]] || [[ $FTPLINK == -1* ]]; then
        echo $NEED_LOGIN_AGIAN
        exit 1
    fi

    FTPMIRROR="lftp \"${FTPLINK}\" -e \"mirror --continue --parallel=10\
        /htdocs `echo ~`/FTP\""
    FTPMIRROR=`echo "${FTPMIRROR}" | sed -e"s/  */ /g"`

    if [[ $PART2 -eq 0 ]]; then
        echo "  FTP Link:                 ${FTPLINK}"
        echo "  FTP Mirror Command:       ${FTPMIRROR}"
    fi
fi

# Space Usage

if [[ $ARGUMENTS_COUNT -eq 0 ]] || [[ $PART3 -eq 1 ]]; then

    INFO=`$CURL -s -L "${QUERY_URL}?action=GetIndexSpaceDiv" \
    -b "${COOKIE}" \
    -c "${COOKIE}" \
    -A "${USER_AGENT}" | iconv -f gbk`

    if [[ ${#INFO} -eq 0 ]] || [[ $INFO == -1* ]]; then
        echo $NEED_LOGIN_AGIAN
        exit 1
    fi

    SPACEUSED=${INFO##*&nbsp;}
    SPACEUSED=${SPACEUSED/使用}
    SPACEUSED=${SPACEUSED/\/总/ used, }
    SPACEUSED="${SPACEUSED} total"

    if [[ $PART3 -eq 0 ]]; then
        echo "  Space Usage:              ${SPACEUSED}"
    fi
fi

# Bandwidth Usage

if [[ $ARGUMENTS_COUNT -eq 0 ]] || [[ $PART4 -eq 1 ]]; then

    INFO=`$CURL -s -L "${QUERY_URL}?action=GetIndexFlowDiv" \
    -b "${COOKIE}" \
    -c "${COOKIE}" \
    -A "${USER_AGENT}" | iconv -f gbk`

    if [[ ${#INFO} -eq 0 ]] || [[ $INFO == -1* ]]; then
        echo $NEED_LOGIN_AGIAN
        exit 1
    fi

    BWUSED=${INFO##*>}

    if [[ $PART4 -eq 0 ]]; then
        echo "  Bandwidth Usage:          ${BWUSED}"
    fi
fi

# Database Name and PhpMyAdmin URL
# Database Host, User Name, Password

if [[ $ARGUMENTS_COUNT -eq 0 ]] || [[ $PART5 -eq 1 ]] || [[ $PART6 -eq 1 ]]
then

    INFO=`$CURL -s -L "${QUERY_URL}?action=GetDBList" \
    -b "${COOKIE}" \
    -c "${COOKIE}" \
    -A "${USER_AGENT}" | iconv -f gbk`

    if [[ ${#INFO} -eq 0 ]] || [[ $INFO == -1* ]]; then
        echo $NEED_LOGIN_AGIAN
        exit 1
    fi

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

    if [[ $PART5 -eq 0 ]] && [[ $PART6 -eq 0 ]]; then
        echo "  phpMyAdmin Link:          ${DBLINK}"
        echo "  Database Name:            ${DBNAME}"
    fi

    if [[ $ARGUMENTS_COUNT -eq 0 ]] || [[ $PART6 -eq 1 ]]; then

        if [[ ${#DBLINK} -eq 0 ]]; then
            echo $NEED_LOGIN_AGIAN
            exit 1
        fi

        IFS=$'\r'

        # remove all previous phpmyadmin login info;
        cat "${COOKIE}" | sed "/phpmyadmin/d" > "${COOKIE}.new"
        mv "${COOKIE}.new" "${COOKIE}"

        PMA=`$CURL -s -L "${DBLINK}" \
        -b "${COOKIE}" \
        -c "${COOKIE}" \
        -A "${USER_AGENT}"`

        # if [[ $PMA =~ token=[a-f0-9]{32} ]]; then # if logged in, log out.
        #     _PMA=${PMA%token=*}
        #     TOKEN=${PMA:$(( ${#_PMA} + 6 )):32}
        #     PMA_INDEX=${DBLINK%%\?*}

        #     PMA=`$CURL -s -L "${PMA_INDEX}?token=${TOKEN}&old_usr=foo" \
        #     -b "${COOKIE}" \
        #     -c "${COOKIE}" \
        #     -A "${USER_AGENT}"`

        #     PMA=`$CURL -s -L "${DBLINK}" \
        #     -b "${COOKIE}" \
        #     -c "${COOKIE}" \
        #     -A "${USER_AGENT}"`
        # fi

        get_value_from PMA starting_from 'id="input_servername"'
        DBHOST=${PMA%%\"*}

        get_value_from PMA starting_from 'id="input_username"'
        DBUSER=${PMA%%\"*}

        get_value_from PMA starting_from 'id="input_password"'
        DBPASS=${PMA%%\"*}

        MYSQLCONNECT="mysql -v -A -h \"${DBHOST}\" \
            -u \"${DBUSER}\" -p\"${DBPASS}\" \"${DBNAME}\""
        MYSQLCONNECT=`echo "${MYSQLCONNECT}" | sed -e"s/  */ /g"`

        SGP=""
        mysqldump --set-gtid-purged=OFF >/dev/null 2>&1
        if [[ $? -eq 1 ]]; then
            SGP="--set-gtid-purged=OFF"
        fi
        MYSQLDUMP="mysqldump ${SGP} -v -h \"${DBHOST}\" \
            -u \"${DBUSER}\" -p\"${DBPASS}\" \"${DBNAME}\" \
            > ${DBNAME}@`date +'%Y%m%d%H%M%S'`.sql"
        MYSQLDUMP=`echo "${MYSQLDUMP}" | sed -e"s/  */ /g"`

        if [[ $PART6 -eq 0 ]]; then
            echo "  Database Host:            ${DBHOST}"
            echo "  Database User Name:       ${DBUSER}"
            echo "  Database Password:        ${DBPASS}"
            echo "  MySQL Backup Command:     ${MYSQLDUMP}"
            echo "  MySQL Connect Command:    ${MYSQLCONNECT}"
        fi
    fi
fi

# Misc

if [[ $ARGUMENTS_COUNT -eq 0 ]] || [[ $PART7 -eq 1 ]]; then

    ASI="ASP.NET_SessionId"
    SETCOOKIE=$(cat "${COOKIE}" | grep "${ASI}" | sed "s/.*${ASI}//")
    SETCOOKIE="document.cookie=\"${ASI}=${SETCOOKIE:1}\";"

    if [[ $PART7 -eq 0 ]]; then
        echo "  Set Cookie:               ${SETCOOKIE}"
    fi
fi

# Output specified info only

if [[ $ARGUMENTS_COUNT -gt 0 ]]; then
    if [[ ${#ARGUMENTS[@]} -gt 0 ]]; then
        for ARG in "${ARGUMENTS[@]}"; do
            echo "${!ARG}"
        done
    else
        echo "Usage: $0 [OPTIONS/ITEMS...]"
        echo "Options:"
        echo "  -h, --help                   Show this help and exit"
        echo "Items:"
        echo "  -id, --site-id               User name"
        echo "  -t, --type                   Type of virtual hosting"
        echo "  -vf, --valid-from            Start date of the bill"
        echo "  -vt, --valid-to              End date of the bill"
        echo "  -s, --status                 Status text of system"
        echo "  -ip, --ip-address            IP Address of virtual hosting"
        echo "  -os, --system                Name of the operating system"
        echo "  -l, --languages              List of languages installed"
        echo "  -web, --web-link             HTTP web link"
        echo "  -webs, --web-links           All links linked to this hosting"
        echo "  -ftp, --ftp-link             FTP link to the server"
        echo "  -sp, --space-usage           Total space used"
        echo "  -bw, --bandwidth-usage       Bandwidth used in this month"
        echo
        echo "  -pma, --phpmyadmin-link      URL to log in to phpMyAdmin"
        echo "  -dbn, --database-name        Name of the database"
        echo "  -dbh, --database-host        Host to connect"
        echo "  -dbu, --database-username    Username to connect to database"
        echo "  -dbp, --database-password    Password to connect to database"
        echo
        echo "  -cftp, --ftp-mirror          Command to download all files"
        echo "  -csql, --mysqldump           Command to backup database"
        echo "  -cmysql, --mysql-connect     Command to connect to database"
        echo "  -c, --cookie                 JavaScript to set cookie"
    fi
fi
