#!/bin/bash
# Export cacti graph to web0.mnt-tech.fr to display it in WordPress
# Version 0.1
# Date 2014-04-16
# Author : Kevin MET (Et y'a pas de quoi etre fier)

set -x

REMOTE_SERVER="web0.mnt-tech.fr"
REMOTE_FOLDER="/home/www/mnt-tech.fr/cacti"
REMOTE_USER="root"
PRIVATE_KEY="/opt/cacti/.ssh/id_rsa.pub"
LOCAL_FOLDER="/opt/cacti/export"

# On envoie tout de l'autre cote
scp -o StrictHostKeyChecking=no -r "$LOCAL_FOLDER" "$REMOTE_USER"@"$REMOTE_SERVER":/"$REMOTE_FOLDER"

# Et on fait un petit chown/chmod des familles
ssh -o StrictHostKeyChecking=no "$REMOTE_USER"@"$REMOTE_SERVER" "chown -R www-data:www-data \"$REMOTE_FOLDER\" && chmod -R 664 \"$REMOTE_FOLDER\""
