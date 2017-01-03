#!/bin/bash -x

set -o errexit    # abort script at first error

function buildImage() {
  local tagname=$1
  local version=$2
  local branch=$BUILD_BRANCH
  if  [ "${branch}" = "master" ]; then
    imagename=$tagname
  else
    imagename=$tagname-development
  fi
  docker build --no-cache -t blacklabelops/volumerize:$imagename .
}

buildImage $1 $2
