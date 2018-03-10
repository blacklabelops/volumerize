#!/bin/bash -x

set -o errexit    # abort script at first error

# Setting environment variables
readonly CUR_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

printf '%b\n' ":: Reading release config...."
source $CUR_DIR/release.sh

readonly PUSH_REPOSITORY=$1
readonly PUSH_IMAGE_VERSION=$IMAGE_VERSION

function retagImage() {
  local tagname=$1
  local repository=$2
  docker tag -f blacklabelops/volumerize:$tagname $repository/blacklabelops/volumerize:$tagname
}

function pushImage() {
  local tagname=$1
  local repository=$2
  if [ "$repository" != 'docker.io' ]; then
    retagImage $tagname $repository
  fi
  docker push $repository/blacklabelops/volumerize:$tagname
}

pushImage $PUSH_IMAGE_VERSION $PUSH_REPOSITORY
