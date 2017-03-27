# Nagios Opcache plugin

This Nagios plugin permits to monitor various metrics on PHP Opcache:
* Ratio hits/misses
* Interned strings memory usage
* Memory usage
* Restarts

## Installation

For a full description of installation process in french, check this link: [Superviser Opcache avec Nagios et Cacti](https://mnt-tech.fr/blog/superviser-opcache-nagios-cacti/)

First, add opcache_status.php in your web folder and check with curl it's working fine. (Of course, change url to opcache_status.php according to your situation)

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

If it's OK, you can now add check_opcache file to your NRPE plugins folder (it's /usr/lib/nagios/plugins/ on Debian/Ubuntu with installation via package manager). Check the rights, you need to set to root:root 755.

`ls -al /usr/lib/nagios/plugins/check_opcache 
-rwxr-xr-x 1 root root 7219 Mar 22 23:11 /usr/lib/nagios/plugins/check_opcache`

You can then check with NRPE user who is usually nagios if it's working good:

`sudo -u nagios /usr/lib/nagios/plugins/check_opcache --url https://mnt-tech.fr/opcache_status.php
OK: Memory 43%, Keys 3%, String Memory 12%, Hits/Misses 6%, Restarts 0`

## Usage

To go further, you can use some more options which are listed in the help:

`Usage: check_opcache --url http://example.com/opcache_status.php [ --keys %W:%C ] [ --memory %W:%C ] [ --string-memory %W:%C ] [ --ratio %W:%C ] [ --restart W:C ]

Example: check_opcache --url http://example.com/opcache_status.php --keys 70:80 --memory 70:80 --string-memory 70:80 --ratio 5:10 --restart 1:2

Options:
--url or -U            The url to the file opcache_status.php

--keys or -K            Number of keys in cache compared to max_accelerated_files
                        You need to use percent for warning and critical thresholds
                        Defaults: warning 80%, critical 90%

--memory or -M          Memory used
                        You need to use percent for warning and critical thresholds
                        Defaults: warning 80%, critical 90%

--string-memory or -S   Memory used by interned strings
                        You need to use percent for warning and critical thresholds
                        Defaults: warning 80%, critical 90%

--ratio or -R           Ratio hits/misses
                        You need to use percent for warning and critical thresholds
                        Defaults: warning 10%, critical 20%

--restart or -F         Number of restarts (oom_restarts and hash_restarts)
                        You need to set numbers of restarts for warning and critical thresholds
                        Defaults: warning 2, critical 5`
`

## Cacti

If you need a cacti templates to collect these metrics, check [Cacti Opcache template](https://github.com/nierdz/admintools/tree/master/cacti/opcache)

## License

GPLv3
