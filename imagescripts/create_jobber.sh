#!/bin/bash

set -o errexit

readonly JOBBER_SCRIPT_DIR=$VOLUMERIZE_HOME

source $CUR_DIR/base.sh

cat > ${JOBBER_SCRIPT_DIR}/periodicBackup <<_EOF_
#!/bin/bash

set -o errexit

source ${VOLUMERIZE_SCRIPT_DIR}/stopContainers
${DUPLICITY_COMMAND} ${DUPLICITY_MODE} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_SOURCE} ${VOLUMERIZE_TARGET}
source ${VOLUMERIZE_SCRIPT_DIR}/startContainers
_EOF_

readonly configfile="/root/.jobber"

JOBBER_CRON_SCHEDULE='0 0 4 * * *'

if [ -n "${VOLUMERIZE_JOBBER_TIME}" ]; then
  JOBBER_CRON_SCHEDULE=${VOLUMERIZE_JOBBER_TIME}
fi

cat > ${configfile} <<_EOF_
---

- name: VolumerizeBackupJob
  cmd: ${JOBBER_SCRIPT_DIR}/periodicBackup
  time: '${JOBBER_CRON_SCHEDULE}'
  onError: Continue
  notifyOnError: false
  notifyOnFailure: false
_EOF_
