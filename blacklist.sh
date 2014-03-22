#!/bin/bash
#set -x
# Constant variables
CURRENT_DIRECTORY="/opt/spamassassin"
SPAM_DIRECTORY="/var/tmp/spamtrap/cur/"
HAM_DIRECORY="/var/tmp/hamtrap/cur/"
BLACKLIST_SPAMASSASSIN="/etc/mail/spamassassin/blacklist.cf"
WHITELIST_SPAMASSASSIN="/etc/mail/spamassassin/whitelist.cf"

# Extract the spammy addresses in sdbox format
doveadm search -u "*@*" mailbox Spam ALL |
while read guser guid uid; do
    doveadm fetch -u "*@*" hdr mailbox-guid $guid uid $uid | grep "From: " | perl -wne'while(/[\w\.\-]+@[\w\.\-]+\w+/g){print "$&\n"}' >> "$CURRENT_DIRECTORY/spam_adresses.txt"
done

# Delete duplicates and cut after the @
sort -u "$CURRENT_DIRECTORY/spam_adresses.txt" | cut -d@ -f 2 > "$CURRENT_DIRECTORY/spam_domains.txt"

# Echo the domains in blacklist.cf
for domain in $(cat $CURRENT_DIRECTORY/spam_domains.txt)
do
    echo "blacklist_from *@$domain" >> "$BLACKLIST_SPAMASSASSIN"
done

# Remove duplicates from blacklist.cf
cat "$BLACKLIST_SPAMASSASSIN" | sort -u > tmp_blacklist.cf
mv -f tmp_blacklist.cf "$BLACKLIST_SPAMASSASSIN"

#Remove white domains from blacklist.cf
sort -u white_domains.txt > tmp_white_domains.txt
mv tmp_white_domains.txt white_domains.txt
comm -2 -3 "$BLACKLIST_SPAMASSASSIN" white_domains.txt > tmp_blacklist.cf
mv -f tmp_blacklist.cf "$BLACKLIST_SPAMASSASSIN"

#Add white domains to whitelist.cf
cat white_domains.txt > "$WHITELIST_SPAMASSASSIN"

# Copy the spam mails in temp directory
doveadm search -u "*@*" mailbox Spam ALL |
 while read guser guid uid; do
doveadm fetch -u "*@*" text mailbox-guid $guid uid $uid > $SPAM_DIRECTORY/msgspam.$uid
done

# Copy the ham mail in temp directory
doveadm search -u "*@*" mailbox INBOX ALL |
 while read guser guid uid; do
doveadm fetch -u "*@*" text mailbox-guid $guid uid $uid > $HAM_DIRECTORY/msgham.$uid
done

# Start the learning
su -c "/usr/bin/sa-learn --spam $SPAM_DIRECTORY" amavis
su -c "/usr/bin/sa-learn --ham $HAM_DIRECORY" amavis
su -c "/usr/bin/sa-learn --sync" amavis

# Backup rules and blacklist.cf
sa-learn --backup > rules.txt
cp "$BLACKLIST_SPAMASSASSIN" "$CURRENT_DIRECTORY/blacklist.cf"

# Clean up the temp directories
rm $SPAM_DIRECTORY/msgspam* > /dev/null 2>&1
rm $HAM_DIRECTORY/msgham* > /dev/null 2>&1

# Clean up the spam directory
doveadm search -u "*@*" mailbox Spam ALL |
 while read guser guid uid; do
doveadm expunge -u "*@*" mailbox Spam mailbox-guid $guid uid $uid
done

# Clean up
rm spam_adresses.txt
rm spam_domains.txt
