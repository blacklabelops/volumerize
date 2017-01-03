#!/bin/bash -x

set -o errexit    # abort script at first error

function testPrintVersion() {
  local tagname=$1
  local branch=$BUILD_BRANCH
  if  [ "${branch}" = "master" ]; then
    imagename=$tagname
  else
    imagename=$tagname-development
  fi
  docker run --rm blacklabelops/volumerize:$imagename echo
}

testPrintVersion $1
