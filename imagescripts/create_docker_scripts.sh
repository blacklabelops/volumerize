#!/bin/bash

set -o errexit

readonly DOCKER_SCRIPT_DIR=$VOLUMERIZE_HOME

DOCKER_CONTAINERS=""

cat > ${VOLUMERIZE_SCRIPT_DIR}/stopContainers <<_EOF_
#!/bin/bash

set -o errexit
_EOF_

cat > ${VOLUMERIZE_SCRIPT_DIR}/startContainers <<_EOF_
#!/bin/bash

set -o errexit
_EOF_

if [ -n "${VOLUMERIZE_CONTAINERS}" ]; then
  DOCKER_CONTAINERS=${VOLUMERIZE_CONTAINERS}
  for container in $DOCKER_CONTAINERS
  do
    cat >> ${VOLUMERIZE_SCRIPT_DIR}/stopContainers <<_EOF_
docker stop ${container}
_EOF_
    cat >> ${VOLUMERIZE_SCRIPT_DIR}/startContainers <<_EOF_
docker start ${container}
_EOF_
  done
fi
