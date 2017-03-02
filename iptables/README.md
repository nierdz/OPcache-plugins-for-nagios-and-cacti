iptables
========

This is yet another iptables script

This script have been tested only on Debian squeeze and wheezy for the moment.
Use it at your own risks !

You have to put this script in /etc/init.d/ and give hime the good rights.
On debian, it looks like this 7 simple steps :

1. cd /etc/init.d/
2. wget https://git.mnt-tech.fr/iptables.git/raw/master/iptables/iptables
3. chmod 755 iptables
4. insserv -d iptables
5. mkdir /etc/iptables && cd /etc/iptables
6. wget https://git.mnt-tech.fr/iptables.git/raw/master/iptables/iptables.conf
7. /etc/init.d/iptables test

Be carefull, some variables in the configuration file use bash arrays.
So you have to increment yourself these variables starting at 1.

List of these varibales :
1.  PAT_TCP_SERVICES
2.  PAT_UDP_SERVICES
3.  MASQUERADE_SUBNET

