How to use check_integrit
=========================

* First install sudo and integrit
```
apt-get install sudo integrit
```
* Then configure sudo ton enable the nrpe user to launch integrit
```
visudo
```
```
# NRPE
%nagios ALL = NOPASSWD: /usr/sbin/integrit
```
* Then you can use this plugin like this in your commands.cfg :
```
# 'check_nrpe' command definition
define command{
        command_name    check_nrpe
        command_line    $USER1$/check_nrpe -t 300 -H $HOSTADDRESS$ -c $ARG1$
}
```
* Notice the parameter -t 300 which is sometimes usefull as integrit take a lot of times to execute

* When you want to update your database after a false alert, you can use db_update.sh
