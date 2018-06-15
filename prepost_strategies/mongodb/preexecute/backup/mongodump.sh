source /preexecute/utils/check-env.sh

check_env "mongodump" "MONGO_USERNAME" "MONGO_PASSWORD" "MONGO_HOST" "MONGO_PORT"

echo "Creating $VOLUMERIZE_SOURCE folder if not exists"
mkdir -p $VOLUMERIZE_SOURCE

echo "mongodump starts"
mongodump --host ${MONGO_HOST} --port ${MONGO_PORT} --username ${MONGO_USERNAME} --password "${MONGO_PASSWORD}" --out ${VOLUMERIZE_SOURCE}