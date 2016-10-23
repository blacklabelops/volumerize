#!/bin/bash

set -o errexit

readonly VOLUMERIZE_SCRIPT_DIR=$VOLUMERIZE_HOME

source $CUR_DIR/base.sh

cat > ${VOLUMERIZE_SCRIPT_DIR}/backup <<_EOF_
#!/bin/bash

set -o errexit

exec ${DUPLICITY_COMMAND} incremental ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_SOURCE} ${VOLUMERIZE_TARGET}
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/backupFull <<_EOF_
#!/bin/bash

set -o errexit

exec ${DUPLICITY_COMMAND} full ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_SOURCE} ${VOLUMERIZE_TARGET}
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/restore <<_EOF_
#!/bin/bash

set -o errexit

exec ${DUPLICITY_COMMAND} restore --force ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_TARGET} ${VOLUMERIZE_SOURCE}
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/verify <<_EOF_
#!/bin/bash

set -o errexit

exec ${DUPLICITY_COMMAND} verify --compare-data ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_TARGET} ${VOLUMERIZE_SOURCE}
_EOF_
