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
  if [ ! -n "${PASSPHRASE}" ] && [ ! -n "${VOLUMERIZE_GPG_PUBLIC_KEY}" ] && [ ! -n "${VOLUMERIZE_GPG_PRIVATE_KEY}" ]; then
    DUPLICITY_OPTIONS=$DUPLICITY_OPTIONS" --no-encryption"
  fi
  if [ -n "${GPG_KEY_ID}" ]; then
    DUPLICITY_OPTIONS=$DUPLICITY_OPTIONS" --gpg-options --trust-model=always --encrypt-key ${GPG_KEY_ID}"
  fi
  if [ -n "${VOLUMERIZE_FULL_IF_OLDER_THAN}" ]; then
    DUPLICITY_OPTIONS=$DUPLICITY_OPTIONS" --full-if-older-than ${VOLUMERIZE_FULL_IF_OLDER_THAN}"
  fi
  if [ "${VOLUMERIZE_ASYNCHRONOUS_UPLOAD}" = 'true' ]; then
    DUPLICITY_OPTIONS=$DUPLICITY_OPTIONS" --asynchronous-upload"
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
    VOLUMERIZE_INCLUDES=$VOLUMERIZE_INCLUDES" --include "${!VOLUMERIZE_INCLUDE}
  done
}

JOB_COUNT=

function discoverJobs() {
  local x
  for (( x=1; ; x++ ))
  do
    JOB_VARIABLE="VOLUMERIZE_SOURCE${x}"
    if [ ! -n "${!JOB_VARIABLE}" ]; then
      break
    else
      JOB_COUNT=$x
    fi
  done
}

DUPLICITY_JOB_COMMAND=
DUPLICITY_JOB_OPTIONS=
VOLUMERIZE_JOB_SOURCE=
VOLUMERIZE_JOB_TARGET=
VOLUMERIZE_JOB_INCLUDES=

function prepareJobCommand() {
  local jobNumber=$1
  DUPLICITY_JOB_COMMAND=$DUPLICITY_COMMAND
  DUPLICITY_JOB_OPTIONS="--allow-source-mismatch"
  local CACHE_VARIABLE="VOLUMERIZE_CACHE${jobNumber}"
  if [ -n "${!CACHE_VARIABLE}" ]; then
    DUPLICITY_JOB_OPTIONS=$DUPLICITY_JOB_OPTIONS" --archive-dir=${!CACHE_VARIABLE}"
  else
    DUPLICITY_JOB_OPTIONS=$DUPLICITY_JOB_OPTIONS" --archive-dir=${VOLUMERIZE_CACHE}"
  fi
  if [ -n "${VOLUMERIZE_DUPLICITY_OPTIONS}" ]; then
    DUPLICITY_JOB_OPTIONS=$DUPLICITY_JOB_OPTIONS" "${VOLUMERIZE_DUPLICITY_OPTIONS}
  fi
  if [ ! -n "${PASSPHRASE}" ] && [ ! -n "${VOLUMERIZE_GPG_PUBLIC_KEY}" ] && [ ! -n "${VOLUMERIZE_GPG_PRIVATE_KEY}" ]; then
    DUPLICITY_JOB_OPTIONS=$DUPLICITY_JOB_OPTIONS" --no-encryption"
  fi
  if [ -n "${GPG_KEY_ID}" ]; then
    DUPLICITY_JOB_OPTIONS=$DUPLICITY_JOB_OPTIONS" --gpg-options --trust-model=always --encrypt-key ${GPG_KEY_ID}"
  fi
  if [ -n "${VOLUMERIZE_FULL_IF_OLDER_THAN}" ]; then
    DUPLICITY_JOB_OPTIONS=$DUPLICITY_JOB_OPTIONS" --full-if-older-than ${VOLUMERIZE_FULL_IF_OLDER_THAN}"
  fi
  if [ "${VOLUMERIZE_ASYNCHRONOUS_UPLOAD}" = 'true' ]; then
    DUPLICITY_JOB_OPTIONS=$DUPLICITY_JOB_OPTIONS" --asynchronous-upload"
  fi
}

function prepareJobConfiguration() {
  local jobNumber=$1
  local VARIABLE_SOURCE="VOLUMERIZE_SOURCE${jobNumber}"
  local VARIABLE_TARGET="VOLUMERIZE_TARGET${jobNumber}"

  if [ -n "${!VARIABLE_SOURCE}" ]; then
    VOLUMERIZE_JOB_SOURCE=${!VARIABLE_SOURCE}
  else
    VOLUMERIZE_JOB_SOURCE=
  fi
  if [ -n "${!VARIABLE_TARGET}" ]; then
    VOLUMERIZE_JOB_TARGET=${!VARIABLE_TARGET}
  else
    VOLUMERIZE_JOB_TARGET=
  fi
}

function resolveJobIncludes() {
  local jobNumber=$1
  local x
  local VARIABLE_INCLUDE
  VOLUMERIZE_JOB_INCLUDES=
  for (( x=1; ; x++ ))
  do
    VARIABLE_INCLUDE="VOLUMERIZE_INCLUDE${jobNumber}_${x}"
    if [ ! -n "${!VARIABLE_INCLUDE}" ]; then
      break
    fi
    VOLUMERIZE_JOB_INCLUDES=$VOLUMERIZE_JOB_INCLUDES" --include "${!VARIABLE_INCLUDE}
  done
}

function prepareJob() {
  local jobNumber=$1
  JOB_VARIABLE="VOLUMERIZE_SOURCE${jobNumber}"
  if [ -n "${!JOB_VARIABLE}" ]; then
    prepareJobCommand $jobNumber
    prepareJobConfiguration $jobNumber
    resolveJobIncludes $jobNumber
  fi
}

resolveIncludes
resolveOptions
discoverJobs
