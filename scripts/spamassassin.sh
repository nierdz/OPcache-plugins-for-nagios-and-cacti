#!/bin/bash
# Author Kevin MET https://mnt-tech.fr/
# The first part sends all domains from mails in junk folder to spamassassin's blacklist
# The second part learn ham and spam
# The third part deletes mails in spam folder
# The last part remove blacklisted domains from inbox mails

# Directories containing mail in Maildir format
USER_DIR[0]=/var/vmail/vmail1/mnt-tech.fr/k/e/v/kevin.met-2015.09.14.16.40.21/Maildir
USER_DIR[1]=/var/vmail/vmail1/mnt-tech.fr/k/e/v/kevin.met-2015.09.14.16.40.21/Maildir/.FRnOG
USER_DIR[2]=/var/vmail/vmail1/mnt-tech.fr/k/e/v/kevin.met-2015.09.14.16.40.21/Maildir/.FRsAG

# Domains you don't want in blacklist and whitelist. Typically domains where you're using a contact form
NEUTRAL_DOMAIN[0]="mad-rabbit.com"

# Other parameters
SPAM_DIR=".Junk"
BLACKLIST_CF="/etc/spamassassin/blacklist.cf"
WHITELIST_CF="/etc/spamassassin/whitelist.cf"

# Loop around all the spam directories and extract the spammy domains
for dir in "${USER_DIR[@]}"
do
	grep -R "From: \|Reply-To: " $dir/$SPAM_DIR | grep -o "<.*>" | cut -d @ -f 2 | sed 's/>//' | grep -E '^(([a-zA-Z](-?[a-zA-Z0-9])*)\.)*[a-zA-Z](-?[a-zA-Z0-9])+\.[a-zA-Z]{2,}$' >> /tmp/bl-domains-$$
done

# Send all domains from blacklist.cf to the tmp file
cut -d @ -f 2 $BLACKLIST_CF >> /tmp/bl-domains-$$

# Remove duplicates 
sort -u /tmp/bl-domains-$$ -o /tmp/bl-domains-$$

# Remove whitelist from tmp blacklist
cut -d @ -f 2 $WHITELIST_CF | sort -u > /tmp/wl-domains-$$ 
comm -2 -3 /tmp/bl-domains-$$ /tmp/wl-domains-$$ > /tmp/bl-domains-proper$$

# Remove domains you don't want in whitelist and blacklist
for domain in "${NEUTRAL_DOMAIN[@]}"
do
	sed -i "/$domain/d" /tmp/bl-domains-proper$$
done

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

# Remove spams older than 1 week 
doveadm expunge -A mailbox Junk sentbefore 1w

# Remove domains in blacklist from inbox folder, so if you want to remove a blacklisted domain, just add mail to your inbox  
# Loop around all the spam directories and extract the spammy domains
for dir in "${USER_DIR[@]}"
do
	grep -R "From: \|Reply-To: " "$dir/cur/" | grep -o "<.*>" | cut -d @ -f 2 | sed 's/>//' | grep -E '^(([a-zA-Z](-?[a-zA-Z0-9])*)\.)*[a-zA-Z](-?[a-zA-Z0-9])+\.[a-zA-Z]{2,}$' >> /tmp/wl-domains-$$
done

# Remove duplicates
sort -u -o /tmp/wl-domains-$$ /tmp/wl-domains-$$

# We loop around this file containing wl domains and delete them from blacklist
for domain in $(cat /tmp/wl-domains-$$)
do
	sed -i "/$domain/d" ${BLACKLIST_CF}
done
rm /tmp/wl-domains-$$
