#!/bin/bash

set -o errexit

readonly VOLUMERIZE_SCRIPT_DIR=$VOLUMERIZE_HOME

source $CUR_DIR/base.sh

readonly PARAMETER_PROXY='$@'

cat > ${VOLUMERIZE_SCRIPT_DIR}/prepoststrategy << '_EOF_'
#!/bin/bash

set -o errexit

strategy_path=""

case $1 in
    preAction ) strategy_path=/preexecute ;;
    postAction ) strategy_path=/postexecute ;;
    *) echo "Error: prepoststrategy first parameter 'execution phase' must be preAction or postAction"; exit 1 ;;
esac

case $2 in
    backup | verify | restore ) ;;
    *) echo "Error: porepoststrategy second parameter 'duplicity action' must be backup, verify or restore"; exit 1 ;;
esac

strategy_path=$strategy_path/$2

if [ -d "$strategy_path" ]; then
    for f in $strategy_path/*; do
        case "$f" in
            *.sh) echo "running $f"; . "$f" ;;
            *)    echo "ignoring $f" ;;
        esac
        echo
    done
fi
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/backup <<_EOF_
#!/bin/bash

set -o errexit

${VOLUMERIZE_SCRIPT_DIR}/prepoststrategy preAction backup
source ${VOLUMERIZE_SCRIPT_DIR}/stopContainers
${DUPLICITY_COMMAND} ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_SOURCE} ${VOLUMERIZE_TARGET}
source ${VOLUMERIZE_SCRIPT_DIR}/startContainers
PREPOSTSTRATEGY=/postexecute/backup
${VOLUMERIZE_SCRIPT_DIR}/prepoststrategy postAction backup
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/backupIncremental <<_EOF_
#!/bin/bash

set -o errexit

${VOLUMERIZE_SCRIPT_DIR}/prepoststrategy preAction backup
source ${VOLUMERIZE_SCRIPT_DIR}/stopContainers
${DUPLICITY_COMMAND} incremental ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_SOURCE} ${VOLUMERIZE_TARGET}
source ${VOLUMERIZE_SCRIPT_DIR}/startContainers
${VOLUMERIZE_SCRIPT_DIR}/prepoststrategy postAction backup
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/backupFull <<_EOF_
#!/bin/bash

set -o errexit

${VOLUMERIZE_SCRIPT_DIR}/prepoststrategy preAction backup
source ${VOLUMERIZE_SCRIPT_DIR}/stopContainers
${DUPLICITY_COMMAND} full ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_SOURCE} ${VOLUMERIZE_TARGET}
source ${VOLUMERIZE_SCRIPT_DIR}/startContainers
${VOLUMERIZE_SCRIPT_DIR}/prepoststrategy postAction backup
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/restore <<_EOF_
#!/bin/bash

set -o errexit

${VOLUMERIZE_SCRIPT_DIR}/prepoststrategy preAction restore
source ${VOLUMERIZE_SCRIPT_DIR}/stopContainers
${DUPLICITY_COMMAND} restore --force ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_TARGET} ${VOLUMERIZE_SOURCE}
source ${VOLUMERIZE_SCRIPT_DIR}/startContainers
${VOLUMERIZE_SCRIPT_DIR}/prepoststrategy postAction restore
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/verify <<_EOF_
#!/bin/bash

set -o errexit

${VOLUMERIZE_SCRIPT_DIR}/prepoststrategy preAction verify
${DUPLICITY_COMMAND} verify --compare-data ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_TARGET} ${VOLUMERIZE_SOURCE}
${VOLUMERIZE_SCRIPT_DIR}/prepoststrategy postAction verify
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/cleanup <<_EOF_
#!/bin/bash

set -o errexit

exec ${DUPLICITY_COMMAND} cleanup ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_TARGET}
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/list <<_EOF_
#!/bin/bash

set -o errexit

exec ${DUPLICITY_COMMAND} collection-status ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_TARGET}
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/remove-older-than <<_EOF_
#!/bin/bash

set -o errexit

exec ${DUPLICITY_COMMAND} remove-older-than ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_TARGET}
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/remove-all-but-n-full <<_EOF_
#!/bin/bash

set -o errexit

exec ${DUPLICITY_COMMAND} remove-all-but-n-full ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_TARGET}
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/remove-all-inc-of-but-n-full <<_EOF_
#!/bin/bash

set -o errexit

exec ${DUPLICITY_COMMAND} remove-all-inc-of-but-n-full ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_TARGET}
_EOF_

FILENAME_VARIABLE='$filename'

cat > ${VOLUMERIZE_SCRIPT_DIR}/cleanCacheLocks <<_EOF_
#!/bin/bash

set -o errexit

find /volumerize-cache/ -maxdepth 2 -type f -name lockfile.lock | while read filename ; do fuser -s ${FILENAME_VARIABLE} || rm -fv ${FILENAME_VARIABLE} ; done
_EOF_
