#!/bin/bash -x

set -o errexit    # abort script at first error

# Setting environment variables
readonly CUR_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

printf '%b\n' ":: Reading release config...."
source $CUR_DIR/release.sh

readonly BUILD_IMAGE_VERSION=$IMAGE_VERSION

source $CUR_DIR/buildImage.sh latest latest
source $CUR_DIR/buildImage.sh $BUILD_IMAGE_VERSION $BUILD_IMAGE_VERSION
