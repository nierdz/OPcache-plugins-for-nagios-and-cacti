#!/bin/bash
# Author Kevin MET https://mnt-tech.fr/
# The first part sends all domains from mails in junk folder to spamassassin's blacklist
# The second part learn ham and spam
# The last part deletes mails in spam folder

USER_DIR[0]=/var/vmail/vmail1/mnt-tech.fr/k/e/v/kevin.met-2015.09.14.16.40.21/Maildir
USER_DIR[1]=/var/vmail/vmail1/ad-tech.ovh/a/d/m/admin-2015.09.14.21.55.14/Maildir
SPAM_DIR=".Junk"
BLACKLIST_CF="/etc/spamassassin/blacklist.cf"
WHITELIST_CF="/etc/spamassassin/whitelist.cf"

# Loop around all the spam directories and extract the spammy domains
for dir in "${USER_DIR[@]}"
do
	grep -R "From: \|Reply-To: " $dir/$SPAM_DIR | grep -o "<.*>" | cut -d @ -f 2 | sed 's/>//' >> /tmp/bl-domains-$$
done

# Send all domains from blacklist.cf to the tmp file
cut -d @ -f 2 $BLACKLIST_CF >> /tmp/bl-domains-$$

# Remove duplicates 
sort -u /tmp/bl-domains-$$ -o /tmp/bl-domains-$$

# Remove whitelist from tmp blacklist
cut -d @ -f 2 $WHITELIST_CF | sort -u > /tmp/wl-domains-$$ 
comm -2 -3 /tmp/bl-domains-$$ /tmp/wl-domains-$$ > /tmp/bl-domains-proper$$

# Send back data to blacklist.cf
sed 's/^/blacklist_from *@/' /tmp/bl-domains-proper$$ > $BLACKLIST_CF

# Cleaning
rm /tmp/bl-domains-$$
rm /tmp/wl-domains-$$
rm /tmp/bl-domains-proper$$

# Learning Ham and Spam
for dir in "${USER_DIR[@]}"
do
	sa-learn --spam --username=amavis $dir/$SPAM_DIR/cur
	sa-learn --ham --username=amavis $dir/cur
done

# Remove spams 
doveadm expunge -A mailbox Junk all
