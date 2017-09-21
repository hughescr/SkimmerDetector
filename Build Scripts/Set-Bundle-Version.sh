#!/bin/bash

# Make sure to pick up homebrew/macports in the path ahead of built-ins so that we get the latest "git" and "date"
export PATH="/usr/local/opt/coreutils/libexec/gnubin/:/usr/local/bin:/opt/local/bin:${PATH/:\/@(opt|usr)\/local\/bin/}"

cd "${PROJECT_DIR}"
GIT_REVISION=$(git describe --tags --dirty) || GIT_REVISION=$(git rev-parse --short=8 HEAD | tr 'a-f' 'A-F') || GIT_REVISION='Unknown'
[ "${CONFIGURATION}" != "Release" ] && DEV_SUFFIX="-${CONFIGURATION}"

# Date/timestamp in a CFBundleVersion-compatible always-incrementing string (module datetime does not always
#  increase per http://infiniteundo.com/post/25326999628/falsehoods-programmers-believe-about-time and
#  http://infiniteundo.com/post/25509354022/more-falsehoods-programmers-believe-about-time)
# The tr will deal with "date" commands which can't do nanoseconds
# The "cut" will chop down to a max of 17 characters (18 is app store limit) which will include milliseconds
BUILD_DATESTAMP=$(date +'%Y.%m.%d%H%M%S%N' | tr 'N' '0' | cut -c1-17)

INFO_PLIST="${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"

echo Setting version string to "${GIT_REVISION}${DEV_SUFFIX}"
defaults write "${INFO_PLIST}" CFBundleShortVersionString "${GIT_REVISION}${DEV_SUFFIX}"
defaults write "${INFO_PLIST}" CFBundleVersion "${BUILD_DATESTAMP}"
