#!/bin/bash

set -o errexit

readonly VOLUMERIZE_SCRIPT_DIR=$VOLUMERIZE_HOME

cat > ${VOLUMERIZE_SCRIPT_DIR}/backup <<_EOF_
#!/bin/bash

set -o errexit

_EOF_

source $CUR_DIR/base.sh

cat >> ${VOLUMERIZE_SCRIPT_DIR}/backup <<_EOF_
exec ${DUPLICITY_COMMAND} ${DUPLICITY_MODE} ${DUPLICITY_OPTIONS} ${VOLUMERIZE_INCUDES} ${VOLUMERIZE_SOURCE} ${VOLUMERIZE_TARGET}
_EOF_
