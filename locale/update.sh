#!/bin/bash
# NET.CN Utils
# https://github.com/caiguanhao/net.cn-utils
# Copyright (c) 2013, Cai Guanhao (Choi Goon-ho) All rights reserved.

# Usage: bash update.sh [locale] ...

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MAIN="$( dirname "$DIR" )"

MSGUNIQ="$(which msguniq)"
MSGMERGE="$(which msgmerge)"
MSGFMT="$(which msgfmt)"

if [[ $(( ${#MSGUNIQ} * ${#MSGUNIQ} * ${#MSGUNIQ} )) -eq 0 ]]; then
    echo "Need msguniq, msgmerge and msgfmt from GNU gettext."
    echo "Please install gettext first."
    exit 1
fi

IFS=$'\n'

LOCALES=($(find "${DIR}"/* -maxdepth 0 -type d))

SHELL_FILES=($(find "${MAIN}" -maxdepth 1 -type f -name "*.sh"))

if [[ $# -gt 0 ]]; then
    C_LC=()
    for ARG in "$@"; do
        for LC in "${LOCALES[@]}"; do
            LC_F=${LC##*/}
            if [[ $ARG == $LC_F ]]; then
                C_LC=("${C_LC[@]}" "$LC_F")
            fi
        done
    done
    if [[ ${#C_LC[@]} -ne $# ]]; then
        echo "At least one locale does not exist."
        exit 1
    fi
    LOCALES=("${C_LC[@]}")
fi

CHECK()
{
    if [[ $? -ne 0 ]]; then
        echo "Fail"
        exit 1
    fi
}

for LC in "${LOCALES[@]}"; do
    LC_F=${LC##*/}
    for SF in "${SHELL_FILES[@]}"; do
    SF_D=${SF%/*}
    SF_F=${SF##*/}
        echo -n "Processing $SF_F for $LC_F ... "
        LC_M="${DIR}/${LC_F}/LC_MESSAGES"
        FILE="${LC_M}/${SF_F}"
        if [[ ! -d "$LC_M" ]]; then
            mkdir "$LC_M"
        fi
        if [[ ! -f "${FILE}.po" ]]; then
            cd "$SF_D" && $BASH --dump-po-strings "${SF_F}" > "${FILE}.po"
            $MSGUNIQ -o "${FILE}.po" "${FILE}.po" >/dev/null 2>&1
            CHECK
            echo 'msgid ""
msgstr ""
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"
' | cat - "${FILE}.po" > "${FILE}.po~" && mv "${FILE}.po~" "${FILE}.po"
            echo "Done"
        else
            cd "$SF_D" && $BASH --dump-po-strings "${SF_F}" > "${FILE}.po2"
            $MSGUNIQ -o "${FILE}.po2" "${FILE}.po2" >/dev/null 2>&1
            CHECK
            $MSGMERGE --backup=none --update "${FILE}.po" "${FILE}.po2" >/dev/null 2>&1
            CHECK
            $MSGFMT -o "${FILE}.mo" "${FILE}.po" >/dev/null 2>&1
            CHECK
            rm -f "${FILE}.po2"
            echo "Done"
        fi
    done
done
