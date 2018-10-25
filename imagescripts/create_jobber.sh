#!/bin/bash

set -o errexit

readonly JOBBER_SCRIPT_DIR=$VOLUMERIZE_HOME

source $CUR_DIR/base.sh

JOBBER_CRON_SCHEDULE='0 0 4 * * *'

if [ -n "${VOLUMERIZE_JOBBER_TIME}" ]; then
  JOBBER_CRON_SCHEDULE=${VOLUMERIZE_JOBBER_TIME}
fi

JOB_NAME1=VolumerizeBackupJob
JOB_COMMAND1=${JOBBER_SCRIPT_DIR}/periodicBackup
JOB_TIME1=$JOBBER_CRON_SCHEDULE
JOB_ON_ERROR1=Continue
JOB_NOTIFY_ERR1=false
JOB_NOTIFY_FAIL1=false

readonly configfile="/root/.jobber"

function pipeEnvironmentVariables() {
  local environmentfile="/etc/profile.d/jobber.sh"
  cat > ${environmentfile} <<_EOF_
  #!/bin/sh
_EOF_
  sh -c export >> ${environmentfile}
  sed -i.bak '/^export [a-zA-Z0-9_]*:/d' ${environmentfile}
}

if [ ! -f "${configfile}" ]; then
  touch ${configfile}

  cat >> ${configfile} <<_EOF_
---

_EOF_
  for (( i = 1; ; i++ ))
  do
    VAR_JOB_ON_ERROR="JOB_ON_ERROR$i"
    VAR_JOB_NAME="JOB_NAME$i"
    VAR_JOB_COMMAND="JOB_COMMAND$i"
    VAR_JOB_TIME="JOB_TIME$i"
    VAR_JOB_NOTIFY_ERR="JOB_NOTIFY_ERR$i"
    VAR_JOB_NOTIFY_FAIL="JOB_NOTIFY_FAIL$i"

    if [ ! -n "${!VAR_JOB_NAME}" ]; then
      break
    fi

    it_job_on_error=${!VAR_JOB_ON_ERROR:-"Continue"}
    it_job_name=${!VAR_JOB_NAME}
    it_job_time=${!VAR_JOB_TIME}
    it_job_command=${!VAR_JOB_COMMAND}
    it_job_notify_error=${!VAR_JOB_NOTIFY_ERR:-"false"}
    it_job_notify_failure=${!VAR_JOB_NOTIFY_FAIL:-"false"}

    cat >> ${configfile} <<_EOF_
- name: ${it_job_name}
  cmd: ${it_job_command}
  time: '${it_job_time}'
  onError: ${it_job_on_error}
  notifyOnError: ${it_job_notify_error}
  notifyOnFailure: ${it_job_notify_failure}

_EOF_
  done
fi

cat ${configfile}
