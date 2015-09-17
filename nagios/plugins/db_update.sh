#! /bin/bash
integrit -C /etc/integrit/integrit.conf -u
mv /var/lib/integrit/current.cdb  /var/lib/integrit/known.cdb
