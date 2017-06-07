#!/usr/bin/perl
#
# script to remove some of the more sensitive information from a router
# config file
#
# usage: perl CiscoStripData.pl config.cfg > config-clean.cfg
#

my $configf;
undef $/;

$configf = shift(@ARGV);

if (open(CNFG, $configf ) ) {
	$config=<CNFG>;
	close (CNFG);
	$config =~ s/password .*/password <removed>/gi;
	$config =~ s/secret .*/secret <removed>/gi;
	$config =~ s/community [^ ]+/community <removed>/gi;
	$config =~ s/tacacs-server key.*/tacacs-server key <removed>/gi;
	$config =~ s/128bit 7.*/128bit 7 <removed>/gi;

	print $config;
} else {
	print STDERR "Failed to open config file \"$configf\"\n";
}
