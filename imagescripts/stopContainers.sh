#!/bin/bash

set -e

[[ ${DEBUG} == true ]] && set -x

function stopContainers() {
  local arrayContainers=
  IFS=' ' read -r -a arrayContainers <<< "$1"
  local min=0
  local max=$(( ${#arrayContainers[@]} ))

  for (( i=$min; i<$max; i++ ))
  do
    docker stop "${arrayContainers[$i]}" || true
  done
}

if [ -n "${VOLUMERIZE_CONTAINERS}" ]; then
  stopContainers "${VOLUMERIZE_CONTAINERS}"
fi
