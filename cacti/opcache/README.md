# Cacti Opcache template

This Cacti template permits to monitor various metrics on PHP Opcache:
* Ratio hits/misses
* Cached keys
* Cached scripts
* Interned strings memory usage
* Memory usage

Here is some screenshots:

![Cacti graphics php opcache ratio hits misses](https://mnt-tech.fr/images/blog/cacti-opcache-ratio-hits-misses.jpg)
![Cacti graphics php opcache cached keys](https://mnt-tech.fr/images/blog/cacti-opcache-keys.jpg)
![Cacti graphics php opcache cached scripts](https://mnt-tech.fr/images/blog/cacti-opcache-scripts.jpg)
![Cacti graphics php opcache interned strings memory usage](https://mnt-tech.fr/images/blog/cacti-opcache-interned-strings-memory.jpg)
![Cacti graphics php opcache memory usage](https://mnt-tech.fr/images/blog/cacti-opcache-memory.jpg)


## Installation

For a full description of installation process in french check this link: [Superviser Opcache avec Nagios et Cacti](https://mnt-tech.fr/blog/superviser-opcache-nagios-cacti/)

First, add opcache_status.php in your web folder.

Then, extend your snmpd configuration addind this line:

`# To monitor PHP Opcache
extend phpopcache /usr/bin/curl --silent https://mnt-tech.fr/opcache_status.php`

Of course you need to change the url to opcache_status.php according to your situation.

Restart snmmpd daemon

Verify everything is working fine, first with curl then using snmpwalk:

`/usr/bin/curl --silent https://mnt-tech.fr/opcache_status.php
43934560
90283168
0
251
451
16229
38696
251
4218680
12558536
0
0`

`snmpwalk -v 2c 127.0.0.1 -c "communitypassword" NET-SNMP-EXTEND-MIB::nsExtendOutLine.\"phpopcache\".10
NET-SNMP-EXTEND-MIB::nsExtendOutLine."phpopcache".10 = STRING: 12558536`

If all went good you can now import the cacti template and start adding graphics to your devices.

## Credits

All credits goes to Glen Pitt-Pladdy [Original Opcache Cacti template](https://github.com/glenpp/cacti-php-opcache)

## License

GPLv3
