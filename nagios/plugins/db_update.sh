#! /bin/bash
integrit -C /etc/integrit/nagios.conf -u
mv /var/lib/integrit/current.cdb  /var/lib/integrit/known.cdb
find /tmp/ -name 'integrit-*' && rm -rf /tmp/integrit-*
