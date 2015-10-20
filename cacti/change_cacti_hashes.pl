#!/usr/bin/perl
# This script permits to change all the hashes in an export from cacti
# Author : Kevin MET (https://mnt-tech.fr/)
# Use it when you save and modify an export from cacti and reimport without screwing the template exported
# For example, you export the template to graph some bind logs
# You modify it accordly to your need, let's say you want to graph apache logs
# Once you finished your modifications run this script to change all the hashes and reimport to cacti


use strict;
use warnings FATAL => 'all';

use Digest::MD5 qw(md5_hex);
use Time::HiRes qw(gettimeofday);

# It refers to http://docs.cacti.net/howto:determine_cacti_template_version
my $cacti_version='0024';

# Perl hash containing old_hash and new hash
my %seen; # old_hash -> new_hash

# The pattern to match only the 32 digits in cacti hashes
my $hash_pattern = qr/hash_[0-9]{2}$cacti_version([a-fA-F0-9]+)/;

# Loop line by line around xml file
while ( my $line = <> ) {
	my ( $old_hash ) = $line =~ m/$hash_pattern/g;
	if ( $old_hash ) {
		die "hash $old_hash isn't the right length" unless length($old_hash) == 32;
		if (exists($seen{$old_hash})) {
			$line =~ s/$old_hash/$seen{$old_hash}/;
		} 
		else {
			my $new_hash = md5_hex('abcd' . gettimeofday() . rand());
			$seen{"$old_hash"}="$new_hash";
			$line =~ s/$old_hash/$new_hash/;
		}
	}
	print $line;
}
