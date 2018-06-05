source /prexecute/utils/check-env.sh

if [ "$BACKUP_TYPE" = "backup" ] || [ "$BACKUP_TYPE" = "backupIncremental" ] || [ "$BACKUP_TYPE" = "backupFull" ]; then
    check_env "Mysqldump" "MYSQL_PASSWORD" "MYSQL_USERNAME" "MYSQL_HOST" "MYSQL_DATABASE"

    echo "Creating VOLUMERIZE_SOURCE folder if not exists"
    mkdir -p $VOLUMERIZE_SOURCE
    
    echo "mysqldump starts"
    mysqldump --databases "${MYSQL_DATABASE}" --single-transaction --add-drop-database --user="${MYSQL_USERNAME}" --password="${MYSQL_PASSWORD}" --host="${MYSQL_HOST}" > ${VOLUMERIZE_SOURCE}/dump-${MYSQL_DATABASE}.sql
fi