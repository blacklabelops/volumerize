#!/bin/bash

set -o errexit

# Setting environment variables
readonly CUR_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

if [ -n "${VOLUMERIZE_DELAYED_START}" ]; then
  sleep ${VOLUMERIZE_DELAYED_START}
fi

if [ -n "${VOLUMERIZE_SOURCE}" ]; then
  source $CUR_DIR/create_backup.sh
  source $CUR_DIR/create_jobber.sh
fi

if [ "$1" = 'volumerize' ]; then
  exec jobberd
else
  exec "$@"
fi
