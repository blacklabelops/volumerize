source /preexecute/utils/check-env.sh

check_env "mysqlimport" "MYSQL_PASSWORD" "MYSQL_USERNAME" "MYSQL_HOST" "MYSQL_DATABASE"

echo "mysql import starts"
pv ${VOLUMERIZE_SOURCE}/dump-${MYSQL_DATABASE}.sql | mysql -u ${MYSQL_USERNAME} -p${MYSQL_PASSWORD} $MYSQL_DATABASE
echo "Import done"