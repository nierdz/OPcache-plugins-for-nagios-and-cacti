#!/bin/bash

# MySQL backup script using mysqldump
# Using a config file : backup.conf
# Using a config.cnf file for MySQL connection
# Using nsca-ng-client to contact nagios server

DATE=`date +%Y%m%d-%H%M`
LOG="/var/log/mysql_backup.log" # Log
CONFIG_FILE="backup.conf"

# LOG
exec 1> $LOG
exec 2> $LOG

# Function to log and send errors to nagios server
returncheck() {
	if [ $1 -ne 0 ]
		then
			echo "`date +"%Y-%m-%d %H:%M:%S"` $2"
			echo "$NAGIOS_HOSTNAME;MYSQL_BACKUP;2;CRITICAL: $2" | /usr/sbin/send_nsca -c /etc/send_nsca.cfg -d ";"
			exit 1
	fi
}

# Source config file
source $CONFIG_FILE
returncheck $? "Problem during MySQL backup : Impossible to source config file"

# Check Mysql credentials
$MYSQL --silent --raw -e "SELECT @@hostname;"
returncheck $? "Problem during MySQL backup : Impossible to connect to MySQL server"

# Create backup folder
if [ ! -d $BACKUP_DIR ]
then
	mkdir $BACKUP_DIR
	returncheck $? "Problem during MySQL backup : impossible to create backup folder"
fi

# Get list of databases to backup
if [ "$DATABASES" = "ALL" ]
then
	DATABASES=$($MYSQL --silent --raw -e "SHOW DATABASES;" | grep -v "Database\|information_schema\|mysql\|performance_schema")
	returncheck $? "Problem during MySQL backup : impossible to retrieve databases list"
fi

## Dump databases
for DB in $DATABASES
do
	$MYSQLDUMP ${MYSQLDUMP_OPT} --opt --routines --events ${DB} > ${BACKUP_DIR}/${DB}_${DATE}.sql
	returncheck $? "Problem during MySQL backup : impossible to backup database $BASE"
done

## Zip dumps
for DB in $DATABASES
do
	${GZIP} ${BACKUP_DIR}/${DB}_${DATE}.sql
	returncheck $? "Problem during MySQL backup : impossible to zip database $BASE"
done

# Delete old backups
find ${BACKUP_DIR} -name "*.gz" -mtime +${TIME_TO_KEEP} -delete
returncheck $? "Problem during MySQL backup : impossible to delete old backups"

# Send OK to nagios server
echo "$NAGIOS_HOSTNAME;MYSQL_BACKUP;0;OK - Backup done" | /usr/sbin/send_nsca -c /etc/send_nsca.cfg -d ";"
