#!/bin/bash

# MySQL backup script using mydumper and mysqldump
# This script has to be executed directly on the MySQL server
# It sends all the data in a remote host in a folder named by the date
# To install mydumper you can refer to https://mnt-tech.fr/compilation-et-utilisation-de-mydumper/ (French)
# Version 0.1 ### 2014-03-14 ### Author:Kévin MET
# TODO Add support for Nagios NRDP
# TODO Send mydumper output to $LOG

DATE=`date +%Y-%m-%d`
MYSQL_HOST="localhost" # Only use localhost or 127.0.0.1
MYSQL_USER="root"
MYSQL_PASSWORD="password"
MYSQL_SOCKET="/var/run/mysqld/mysqld.sock"
DATABASES="ALL" # List of databases to backup separate by space. Use ALL to backup all databases except the system ones
TMP_DIR="/home/backup/mysql" # Where to stock dumps before sending it to the remote host
LOG="/var/log/mysql_backup.log" # Log
ERROR_LOG="/var/log/mysql_backup_error.log" # Error log
MYDUMPER="/opt/mydumper/bin/mydumper"
MYSQLDUMP="/usr/bin/mysqldump"
MYSQL="/usr/bin/mysql"
RSYNC="/usr/bin/rsync"
SSH="/usr/bin/ssh"
FIND="/usr/bin/find" # PATH to find binary on the remote host
TIME_TO_KEEP="30" # Time in days you want to keep old backups
MYDUMPER_OPT="-c" # Additional options for mydumper
KEEP_LOCAL="ON" # If set to ON, the last backup is keeped locally in $TMP_DIR
REMOTE_HOST="test.example.com"
REMOTE_PORT="22"
REMOTE_USER="root"
REMOTE_KEY="/root/.ssh/id_rsa"
REMOTE_DIR="/home/backup/mysql/web0"

# LOG
exec 1> $LOG
exec 2> $ERROR_LOG

# Check binaries
for BINARY in $MYDUMPER $MYSQL $RSYNC $SSH $FIND
do
	if [ ! -f $BINARY -a ! -x $BINARY ]
	then
		echo "Problem during MySQL backup : $BINARY does not exist"
		exit 1
	fi
done

# Check remote host connexion
REMOTE_CHECK=$($SSH -p $REMOTE_PORT -i $REMOTE_KEY $REMOTE_USER\@$REMOTE_HOST "hostname")
if [ -z $REMOTE_CHECK ]
then
	echo "Problem during MySQL backup : Remote connexion to $REMOTE_HOST does not work\n"
	if [ ! "$KEEP_LOCAL" = "ON" ]
	then
		echo "Stop before dump because remote connexion does not work and KEEP_LOCAL is not activated"
		exit 1
	fi
fi

# Check Mysql credentials
MYSQL_CHECK=$($MYSQL --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" --host="$MYSQL_HOST" --socket="$MYSQL_SOCKET" --silent --raw -e "SELECT @@hostname;")
if [ $? -ne 0 ]
then
	echo "Problem during MySQL backup : Impossible to connect to MySQL server"
	exit 1
fi

# Check mydumper options
for OPTION in $(echo $MYDUMPER_OPT | sed 's#-#\\-#g')
do
	if [ ! $($MYDUMPER --help | grep -c $OPTION) -gt 0 ];
	then
		echo "Problem during MySQL backup : The mydumper option $OPTION does not exist"
		exit 1
	fi
done

# Get list of databases to backup
if [ "$DATABASES" = "ALL" ]
then
	DATABASES=$($MYSQL --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" --host="$MYSQL_HOST" --socket="$MYSQL_SOCKET" --silent --raw -e "SHOW DATABASES;" | grep -v "Warning\|Database\|information_schema\|mysql\|performance_schema")
	if [ $? -ne 0 ]
	then
		echo "Problem during MySQL backup : impossible to retrieve databases list"
		exit 1
	fi
fi

# Dump schemas
for BASE in $DATABASES
do
	mkdir $TMP_DIR/$BASE
	$MYSQLDUMP --no-data --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" --host="$MYSQL_HOST" --socket="$MYSQL_SOCKET" $BASE > $TMP_DIR/$BASE/$BASE-schema.sql
	if [ $? -ne 0 ]
	then
		echo "Problem during MySQL backup : impossible to backup schema of database $BASE"
	fi
done

# Dump data 
for BASE in $DATABASES
do
	$MYDUMPER --no-schemas -o $TMP_DIR/$BASE -B $BASE -u $MYSQL_USER -p $MYSQL_PASSWORD -h $MYSQL_HOST -S $MYSQL_SOCKET $MYDUMPER_OPT
	if [ $? -ne 0 ]
	then
		echo "Problem during MySQL backup : impossible to backup data of database $BASE"
	fi
done

# Rsync to the remote host
for BASE in $DATABASES
do
	$RSYNC --bwlimit=8192 -avz -e "ssh -p $REMOTE_PORT" $TMP_DIR/$BASE $REMOTE_USER\@$REMOTE_HOST:$REMOTE_DIR/$DATE
	if [ $? -ne 0 ]
	then
		echo "Problem during MySQL backup : impossible to rsync $BASE to $REMOTE_HOST"
	fi
done

# Delete old backups
$SSH -p $REMOTE_PORT $REMOTE_USER\@$REMOTE_HOST "$FIND $REMOTE_DIR -type d -mtime +20 -exec rm -r {} \;"

# Delete $TMP_DIR if needed
if [ ! "$KEEP_LOCAL" = "ON" ]
then
	rm -r $TMP_DIR/*
fi

