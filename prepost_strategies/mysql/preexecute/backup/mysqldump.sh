source /preexecute/utils/check-env.sh

check_env "Mysqldump" "MYSQL_PASSWORD" "MYSQL_USERNAME" "MYSQL_HOST" "MYSQL_DATABASE"

echo "Creating $VOLUMERIZE_SOURCE folder if not exists"
mkdir -p $VOLUMERIZE_SOURCE

# Based on this answer https://stackoverflow.com/a/32361604
SIZE_BYTES=$(mysql --skip-column-names -u ${MYSQL_USERNAME} -p${MYSQL_PASSWORD} $MYSQL_DATABASE -e "SELECT ROUND(SUM(data_length * 0.8), 0) FROM information_schema.TABLES WHERE table_schema='${MYSQL_DATABASE}';")

echo "mysqldump starts (Progress is aproximated)"
mysqldump --databases "${MYSQL_DATABASE}" --single-transaction --add-drop-database --user="${MYSQL_USERNAME}" --password="${MYSQL_PASSWORD}" --host="${MYSQL_HOST}" | pv --progress --size "$SIZE_BYTES" > ${VOLUMERIZE_SOURCE}/dump-${MYSQL_DATABASE}.sql