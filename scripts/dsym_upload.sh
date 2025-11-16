#!/bin/sh

function help() {
        cat <<EOF
$(basename ${0}) is a tool for upload dsyms for Firebase Crashlytics
Usage:
  $(basename ${0}) [dsyms.zip path] [Google-Service.plist path]
  e.g.
  $(basename ${0}) "/path/to/dsyms.zip" "/Path/To/GoogleService_info.plist"
EOF
}

cd "$(dirname "$0")"
SCRIPT_PATH="./upload-symbols"
function prepare() {
    if [ ! -e $SCRIPT_PATH ]; then
        curl -L https://github.com/firebase/firebase-ios-sdk/raw/main/Crashlytics/upload-symbols -o $SCRIPT_PATH
        chmod +x $SCRIPT_PATH
    fi
}

if [ $# -ne 2 ]; then
    help
    exit 1
fi

DSYMS_PATH=$1
PLIST_PATH=$2

if [ ! -f "${DSYMS_PATH}" -a ! -d "${DSYMS_PATH}" ]; then
    echo "dsyms not found ${DSYMS_PATH}" 1>&2
    exit 1
fi

prepare
find "${DSYMS_PATH}" -name "*.dSYM" | xargs -I {} ./upload-symbols -gsp ${PLIST_PATH} -p ios {}
