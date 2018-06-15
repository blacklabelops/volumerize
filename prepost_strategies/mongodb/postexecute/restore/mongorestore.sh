source /preexecute/utils/check-env.sh

check_env "mongorestore" "MONGO_USERNAME" "MONGO_PASSWORD" "MONGO_HOST" "MONGO_PORT"

echo "mongorestore starts"
mongorestore --host ${MONGO_HOST} --port ${MONGO_PORT} --username ${MONGO_USERNAME} --password "${MONGO_PASSWORD}" ${VOLUMERIZE_SOURCE}
echo "Import done"