#!/bin/bash

set -o errexit

[[ ${DEBUG} == true ]] && set -x

function pipeEnvironmentVariables() {
  local environmentfile="/etc/profile.d/jobber.sh"
  cat > ${environmentfile} <<_EOF_
  #!/bin/sh
_EOF_
  sh -c export >> ${environmentfile}
}

GPG_KEY_ID=""

# Install GPG Key
if [ ! -f "/root/.gnupg/pubring.kbx" ]; then
  if [ -n "${VOLUMERIZE_GPG_PRIVATE_KEY}" ]; then
    gpg --allow-secret-key-import --import ${VOLUMERIZE_GPG_PRIVATE_KEY}
    GPG_KEY_ID=$(gpg2 --list-secret-keys --keyid-format LONG | grep sec | awk 'NR==1{print $2; exit}')
    GPG_KEY_ID=$(cut -d "/" -f 2 <<< "$GPG_KEY_ID")
  fi

  if [ -n "${VOLUMERIZE_GPG_PUBLIC_KEY}" ]; then
    gpg --import ${VOLUMERIZE_GPG_PUBLIC_KEY}
    GPG_KEY_ID=$(gpg2 --list-keys --keyid-format LONG | grep pub | awk 'NR==2{print $2; exit}')
    GPG_KEY_ID=$(cut -d "/" -f 2 <<< "$GPG_KEY_ID")
  fi
fi

# Setting environment variables
readonly CUR_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

if [ -n "${VOLUMERIZE_DELAYED_START}" ]; then
  sleep ${VOLUMERIZE_DELAYED_START}
fi

if [ -n "${GOOGLE_DRIVE_ID}" ]; then
  source $CUR_DIR/create_gdocs_file.sh
fi

if [ -n "${VOLUMERIZE_JOBBER_TIME}" ]; then
  source $CUR_DIR/create_jobber.sh
fi

if [ "$1" = 'volumerize' ]; then
  pipeEnvironmentVariables
  exec /usr/libexec/jobbermaster
else
  exec "$@"
fi
