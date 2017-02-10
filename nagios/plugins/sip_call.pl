#!/usr/bin/perl

use strict;
use warnings;
use Net::SIP;

my ($destination) = @ARGV;

my $ua = Net::SIP::Simple->new(
	registrar => "sip3.ovh.fr",
	domain => "sip3.ovh.fr",
	from => "0033XXXXXXXXX",
	auth => [ "0033XXXXXXXXX", "XXXXXXXXXXXXXXXX" ],
	expires => 1800,
);

$ua->register or die ("Register failed: ".$ua->error);

$ua->invite( $destination,
	init_media => $ua->rtp( 'media_send_recv', 'announce.pcmu-8000', 2 ),
	rtp_param => [8, 160, 160/8000, 'PCMA/8000'],
	asymetric_rtp => 0,
) or die "Invite failed: ".$ua->error;

$ua->loop;

$ua->bye;
