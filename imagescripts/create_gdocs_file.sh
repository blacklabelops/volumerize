#!/bin/bash

set -o errexit

if [ -n "${GOOGLE_DRIVE_ID}" ] && [ -n "${GOOGLE_DRIVE_SECRET}" ]; then
  cat > /credentials/cred.file <<_EOF_
client_config_backend: settings
client_config:
    client_id: ${GOOGLE_DRIVE_ID}
    client_secret: ${GOOGLE_DRIVE_SECRET}
save_credentials: True
save_credentials_backend: file
save_credentials_file: /credentials/googledrive.cred
get_refresh_token: True
_EOF_
fi
