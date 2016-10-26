#!/bin/bash

set -o errexit

DUPLICITY_COMMAND="duplicity"

DUPLICITY_OPTIONS=""

DUPLICITY_INCLUDES=""

DUPLICITY_TARGET=${VOLUMERIZE_TARGET}

DUPLICITY_MODE=""

function resolveOptions() {
  DUPLICITY_OPTIONS="--allow-source-mismatch --archive-dir=${VOLUMERIZE_CACHE}"
  if [ -n "${VOLUMERIZE_DUPLICITY_OPTIONS}" ]; then
    DUPLICITY_OPTIONS=$DUPLICITY_OPTIONS" "${VOLUMERIZE_DUPLICITY_OPTIONS}
  fi
  if [ ! -n "${PASSPHRASE}" ]; then
    DUPLICITY_OPTIONS=$DUPLICITY_OPTIONS" --no-encryption"
  fi
}

function resolveIncludes() {
  local x
  for (( x=1; ; x++ ))
  do
    VOLUMERIZE_INCLUDE="VOLUMERIZE_INCLUDE${x}"
    if [ ! -n "${!VOLUMERIZE_INCLUDE}" ]; then
      break
    fi
    VOLUMERIZE_INCUDES=$VOLUMERIZE_INCLUDES" --include "${!VOLUMERIZE_INCLUDE}
  done
}

resolveIncludes
resolveOptions
