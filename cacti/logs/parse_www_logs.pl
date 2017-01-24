#!/usr/bin/perl

use strict;
use warnings;
use File::ReadBackwards ;
use POSIX qw(strftime);

# Time five minutes ago in apache format
my $five_minutes = strftime("%d/%b/%Y:%H:%M:%S",localtime(time-300));

# Empty hash containing the status codes
my %hash = (
	'200' =>0,
	'206' =>0,
	'301' =>0,
	'302' =>0,
	'304' =>0,
	'310' =>0,
	'400' =>0,
	'401' =>0,
	'403' =>0,
	'404' =>0,
	'499' =>0,
	'500' =>0,
	'503' =>0);

my $bw = File::ReadBackwards->new( '/var/log/nginx/mad-rabbit.com-ssl_access.log' ) or die "can't read log file $!" ;
while( defined( my $log_line = $bw->readline ) ) {
	$log_line =~ m/([0-9]{1,}\/[a-zA-z]{3}\/[0-9]{4}:[0-9]{2}:[0-9]{2}:[0-9]{2}).*HTTP\/[0-9].[0-9]" ([0-9]{3})/;
	my $date = $1;
	my $status = $2;

	if ($status == 200) {
	$hash{200}++;
	}
	if ($status == 206) {
	$hash{206}++;
	}
	if ($status == 301) {
	$hash{301}++;
	}
	if ($status == 302) {
	$hash{302}++;
	}
	if ($status == 304) {
	$hash{304}++;
	}
	if ($status == 310) {
	$hash{310}++;
	}
	if ($status == 400) {
	$hash{400}++;
	}
	if ($status == 401) {
	$hash{401}++;
	}
	if ($status == 403) {
	$hash{403}++;
	}
	if ($status == 404) {
	$hash{404}++;
	}
	if ($status == 499) {
	$hash{499}++;
	}
	if ($status == 500) {
	$hash{500}++;
	}
	if ($status == 503) {
	$hash{503}++;
	}

	# Stop the loop after retrieve 5 minutes of log
	if ($date le $five_minutes) {
		foreach my $k (sort(keys(%hash))) {
		print "$k $hash{$k}\n";
		}
	last;
	}
}
