#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MAIN="$( dirname "$DIR" )"

MSGUNIQ=$(which msguniq)
MSGMERGE=$(which msgmerge)
MSGFMT=$(which msgfmt)

LOCALES=(
    $(find "${DIR}"/* -maxdepth 0 -type d)
)

SHELL_FILES=(
    $(find "${MAIN}" -maxdepth 1 -type f -name "*.sh")
)

for SF in "${SHELL_FILES[@]}"; do
    SF_D=${SF%/*}
    SF_F=${SF##*/}
    for LC in "${LOCALES[@]}"; do
        LC_F=${LC##*/}
        echo -n "Processing $SF_F for $LC_F ..."
        FILE="${DIR}/${LC_F}/LC_MESSAGES/${SF_F}"
        cd "$SF_D" && $BASH --dump-po-strings "${SF_F}" > "${FILE}.po2"
        $MSGUNIQ -o "${FILE}.po2" "${FILE}.po2"
        $MSGMERGE --backup=none --update "${FILE}.po" "${FILE}.po2"
        $MSGFMT -o "${FILE}.mo" "${FILE}.po"
        rm -f "${FILE}.po2"
    done
done
