#!/bin/bash

set -o errexit

readonly VOLUMERIZE_SCRIPT_DIR=$VOLUMERIZE_HOME

source $CUR_DIR/base.sh

readonly PARAMETER_PROXY='$@'

cat > ${VOLUMERIZE_SCRIPT_DIR}/prexecute << '_EOF_'
#!/bin/bash

set -o errexit

if [ -d "/prexecute" ]; then
    for f in /prexecute/*; do
        case "$f" in
            *.sh) echo "running $f"; . "$f" ;;
            *)    echo "ignoring $f" ;;
        esac
        echo
    done
fi
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/postexecute << '_EOF_'
#!/bin/bash

set -o errexit

if [ -d "/postexecute" ]; then
    for f in /postexecute/*; do
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

source ${VOLUMERIZE_SCRIPT_DIR}/stopContainers
export BACKUP_TYPE=\$(basename -- "\$0")
source ${VOLUMERIZE_SCRIPT_DIR}/prexecute
${DUPLICITY_COMMAND} ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_SOURCE} ${VOLUMERIZE_TARGET}
source ${VOLUMERIZE_SCRIPT_DIR}/postexecute
source ${VOLUMERIZE_SCRIPT_DIR}/startContainers
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/backupIncremental <<_EOF_
#!/bin/bash

set -o errexit

source ${VOLUMERIZE_SCRIPT_DIR}/stopContainers
export BACKUP_TYPE=\$(basename -- "\$0")
source ${VOLUMERIZE_SCRIPT_DIR}/prexecute
${DUPLICITY_COMMAND} incremental ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_SOURCE} ${VOLUMERIZE_TARGET}
source ${VOLUMERIZE_SCRIPT_DIR}/postexecute
source ${VOLUMERIZE_SCRIPT_DIR}/startContainers
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/backupFull <<_EOF_
#!/bin/bash

set -o errexit

source ${VOLUMERIZE_SCRIPT_DIR}/stopContainers
export BACKUP_TYPE=\$(basename -- "\$0")
source ${VOLUMERIZE_SCRIPT_DIR}/prexecute
${DUPLICITY_COMMAND} full ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_SOURCE} ${VOLUMERIZE_TARGET}
source ${VOLUMERIZE_SCRIPT_DIR}/postexecute
source ${VOLUMERIZE_SCRIPT_DIR}/startContainers
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/restore <<_EOF_
#!/bin/bash

set -o errexit

source ${VOLUMERIZE_SCRIPT_DIR}/stopContainers
export BACKUP_TYPE=\$(basename -- "\$0")
source ${VOLUMERIZE_SCRIPT_DIR}/prexecute
${DUPLICITY_COMMAND} restore --force ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_TARGET} ${VOLUMERIZE_SOURCE}
source ${VOLUMERIZE_SCRIPT_DIR}/postexecute
source ${VOLUMERIZE_SCRIPT_DIR}/startContainers
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/verify <<_EOF_
#!/bin/bash

set -o errexit

exec ${DUPLICITY_COMMAND} verify --compare-data ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_TARGET} ${VOLUMERIZE_SOURCE}
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/cleanup <<_EOF_
#!/bin/bash

set -o errexit

exec ${DUPLICITY_COMMAND} cleanup ${PARAMETER_PROXY} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_TARGET}
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
