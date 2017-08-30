#!/bin/bash

# This script checks that all domains declared in a nginx vhost
# file using server_name match the certificate files declared
# with ssl_certificate* option configurations.
# Typical use case: one certificate for multiple domains and
# you want to be sure you didn't miss one domain in your CSR request :)
#
# Usage ./check_cert_nginx.sh /etc/nginx/sites-enabled/example.com.conf
#
# Author: Kévin MET https://mnt-tech.fr
#
# Version 1.0 2017-08-30
# First version, only supports one certificate per vhost file

BASENAME=$(basename "$0")
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

usage() { 
	if [ -n "$1" ]
	then
		echo -e "Error : $1\n"
	fi
	echo -e "Usage: ./${BASENAME} /path/to/vhost/nginx/config/file"
	exit 1
}

# check we got a parameter
if [ -z "$1" ]
then
	usage "You need to give one argument : nginx vhost config file."
fi

# check we got only one parameter
if [ -n "$2" ]
then
	usage "This script take only one parameter : nginx vhost config file."
fi

# check this is a regular file
if [ ! -f "$1" ]
then
	usage "$1 is not a regular file."
fi

# check file is a nginx vhost with ssl
if ! grep "server_name" "$1" >/dev/null
	then
	usage "$1 is not a nginx vhost file."
fi
if ! grep "ssl_certificate_key" "$1" >/dev/null
	then
	usage "$1 does not contain ssl instructions."
fi

# Store all domains
DOMAINS=$(grep -oE "server_name .*" "$1" | sed -e 's/^server_name //' -e 's/;//')

# Store certificate
CERT=$(grep -oE "ssl_certificate .*" "$1" | sed -e 's/^ssl_certificate //' -e 's/;//')

# Extract all domains in this cert
# awk filter on X509v3 Subject Alternative Name
# then read the next line with getline
# and makes some substitutions to format it properly
CERT_DOMAINS=$(openssl x509 -in ${CERT} -noout -text | \
awk '/X509v3 Subject Alternative Name/ {getline;gsub(/ /, "", $0);gsub(/DNS:/,"",$0);gsub(/IPAddress:/,"",$0);gsub(/\,/, "\n", $0); print}')

# Loop around all domains to check if cert hold them
CHECK="KO"
for domain in ${DOMAINS}
do
	for cert_domain in ${CERT_DOMAINS}
	do
		if [ "$domain" == "$cert_domain" ]; then
			CHECK="OK"
		fi
	done
	if [ "${CHECK}" == "OK" ]
	then
		echo -e "${domain}: ${GREEN}OK${NC}"
	else
		echo -e "${domain}: ${RED}KO${NC}"
	fi
	# Reset CHECK
	CHECK="KO"
done


































