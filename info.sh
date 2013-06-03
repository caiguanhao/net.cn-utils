#!/bin/bash

PWD="`pwd`"

CURL=$(which curl)

USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3)"
USER_AGENT="${USER_AGENT} AppleWebKit/537.31 (KHTML, like Gecko)"
USER_AGENT="${USER_AGENT} Chrome/26.0.1410.65 Safari/537.31"

QUERY_URL="http://cp.hichina.com/AJAXPage.aspx"

ARGUMENTS_COUNT=$#

ARGUMENTS=()

PART1=0
PART1_VAR=(     TYPENAME        OPENDATE        ENDDATE         STATUS
                SITEIP          OSNAME          SCRIPTS                     )
PART1_SHORT=(   -t              -vf             -vt             -s
                -ip             -os             -l                          )
PART1_LONG=(    --type          --valid-from    --valid-to      --status
                --ip-address    --system        --languages                 )

PART2=0
PART2_VAR=(     FTPLINK                                                     )
PART2_SHORT=(   -ftp                                                        )
PART2_LONG=(    --ftp-link                                                  )

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
PART6_VAR=(     DBSERVER                        DBUSER
                DBPASS                                                      )
PART6_SHORT=(   -dbs                            -dbu
                -dbp                                                        )
PART6_LONG=(    --database-server               --database-username
                --database-password                                         )

for (( i = 1; i <= $#; i++ )); do
    for (( j = 1; j <= 6; j++ )); do
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
done

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

    if [[ $PART1 -eq 0 ]]; then
        echo "Info for ${SITEID}:"
        echo "  Product Type:             ${TYPENAME}"
        echo "  Valid From:               ${OPENDATE}"
        echo "  Valid To:                 ${ENDDATE}"
        echo "  Status:                   ${STATUS}"
        echo "  IP Address:               ${SITEIP}"
        echo "  Operating System:         ${OSNAME}"
        echo "  Programming Languages:    ${SCRIPTS}"
    fi
fi

# FTP Link

if [[ $ARGUMENTS_COUNT -eq 0 ]] || [[ $PART2 -eq 1 ]]; then

    FTPLINK=`$CURL -s -L "${QUERY_URL}?action=GetWebFtpUrl" \
    -b "${PWD}/cookie" \
    -c "${PWD}/cookie" \
    -A "${USER_AGENT}" | iconv -f gbk`

    if [[ $PART2 -eq 0 ]]; then
        echo "  FTP Link:                 ${FTPLINK}"
    fi
fi

# Space Usage

if [[ $ARGUMENTS_COUNT -eq 0 ]] || [[ $PART3 -eq 1 ]]; then

    INFO=`$CURL -s -L "${QUERY_URL}?action=GetIndexSpaceDiv" \
    -b "${PWD}/cookie" \
    -c "${PWD}/cookie" \
    -A "${USER_AGENT}" | iconv -f gbk`
    SPACEUSED=${INFO##*&nbsp;}

    if [[ $PART3 -eq 0 ]]; then
        echo "  Space Usage:              ${SPACEUSED}"
    fi
fi

# Bandwidth Usage

if [[ $ARGUMENTS_COUNT -eq 0 ]] || [[ $PART4 -eq 1 ]]; then

    INFO=`$CURL -s -L "${QUERY_URL}?action=GetIndexFlowDiv" \
    -b "${PWD}/cookie" \
    -c "${PWD}/cookie" \
    -A "${USER_AGENT}" | iconv -f gbk`
    BWUSED=${INFO##*>}

    if [[ $PART4 -eq 0 ]]; then
        echo "  Bandwidth Usage:          ${BWUSED}"
    fi
fi

# Database Name and PhpMyAdmin URL
# Database Server, User Name, Password

if [[ $ARGUMENTS_COUNT -eq 0 ]] || [[ $PART5 -eq 1 ]] || [[ $PART6 -eq 1 ]]; then

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

    if [[ $PART5 -eq 0 ]] && [[ $PART6 -eq 0 ]]; then
        echo "  PhpMyAdmin Link:          ${DBLINK}"
        echo "  Database Name:            ${DBNAME}"
    fi

    if [[ $ARGUMENTS_COUNT -eq 0 ]] || [[ $PART6 -eq 1 ]]; then

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

        if [[ $PART6 -eq 0 ]]; then
            echo "  Database Server:          ${DBSERVER}"
            echo "  Database User Name:       ${DBUSER}"
            echo "  Database Password:        ${DBPASS}"
        fi
    fi
fi

if [[ $ARGUMENTS_COUNT -gt 0 ]]; then
    for ARG in "${ARGUMENTS[@]}"; do
        echo "${!ARG}"
    done
fi
