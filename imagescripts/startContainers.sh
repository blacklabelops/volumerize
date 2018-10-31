#!/bin/bash

set -e

[[ ${DEBUG} == true ]] && set -x

function startContainers() {
  local arrayContainers=
  IFS=' ' read -r -a arrayContainers <<< "$1"
  local min=0
  local max=$(( ${#arrayContainers[@]} -1))

  for (( i=$max; i>=$min; i-- ))
  do
    docker start ${arrayContainers[$i]} || true
  done
}

if [ -n "${VOLUMERIZE_CONTAINERS}" ]; then
  startContainers "${VOLUMERIZE_CONTAINERS}"
fi
