#!/usr/bin/perl

use warnings;
use strict;

## Julian date conversion comes courtsey of 
##  http://unlser1.unl.csi.cuny.edu/faqs/perl-faq/Q4.12.html
my @theJulianDate = ( 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 );

##
## todd fencl / tfencl@innotrac.com
## cdate: 05/17/2010
## mdate: 02/16/2011
##
##  01.13.2011 - removed model information
##  02.16.2011 - removed DevName and Serial information
##
## define what we are going to need since we used `use strict`
##
my ($snmpComm, $snmpGet, @temp, $jDay);
my ($fPath, $fDevices, $fLog, $fCSV);
my ($oid_Uptime, $oid_Serial, $oid_PageCount, $oid_Vendor, $oid_sysName);
my ($qUptime, $qSerial, $qPageCount, $qSysName, $qVendor);

$snmpComm = "public";
$snmpGet = "/usr/bin/snmpget -v1 -O qv -c $snmpComm";
$fPath = "/media/log/scripts";
$fDevices = "$fPath/printer.devices.lst";
$jDay = &julianDate(time);
$fLog = "$fPath/output/report.$jDay.log";
$fCSV = "$fPath/output/print.collector.csv";

$oid_Vendor 	= ".1.3.6.1.2.1.1.1.0";
$oid_Uptime		= ".1.3.6.1.2.1.1.3.0";
$oid_sysName	= ".1.3.6.1.2.1.1.5.0";
$oid_Serial		= ".1.3.6.1.2.1.43.5.1.1.17.1";
$oid_PageCount	= ".1.3.6.1.2.1.43.10.2.1.4.1.1";

open (DEVICE, "<", "$fDevices") or die "Could not open device file: $fDevices! $!";
while(<DEVICE>) {
	chomp($_);			# remove newline/carriage return from read line
	
	next if (s/#.*//);	# skip if the line is a comments
	next if (/^$/);		# ignore blank lines
	
	##
	## test to see if we can talk to the device, if $? comes back != 0 then 
	## we need to skip as we can't even talk to the device
	##
	if (&pingTest($_) eq "1") {
		open (LOG, ">>", "$fLog");
		printf LOG ("Date: %s", `/bin/date`);
		printf LOG ("*** CRITICAL FAILURE: failed ping test to %s ***\n\n", $_);
		printf LOG ("==================================================\n");
		close LOG;
		print "\nping failed to $_, should move next record\n";
		next; 
	} # fi pingTest

	chomp ($qVendor = `$snmpGet $_ $oid_Vendor`);
	## take the string above, and cut the first 20 characters for display
	## add a * to denote a trim, and make sure to leave the trailing " to 
	## close the string before the , to delim the field
	$qVendor = substr($qVendor, 0, 20) . "*\"";

	## When looking at the uptime we get back 181:22:45:40 as days:hours:min:sec
	## split this up a little to make more sense ... :)
	chomp ($qUptime = `$snmpGet $_ $oid_Uptime`);
	@temp = split(/:/, $qUptime);
	$qUptime = sprintf("%d days %d:%d:%d (h:m:s)", $temp[0], $temp[1], $temp[2], $temp[3]);
	
	$qSysName="";
	$qSerial="";
	$qPageCount=0;
	
	chomp ($qSysName = `$snmpGet $_ $oid_sysName`);
	chomp ($qSerial = `$snmpGet $_ $oid_Serial`);
	chomp ($qPageCount = `$snmpGet $_ $oid_PageCount`);
	
	## We need to append to the log since we open each time we write a record 
	## instead of opening at the beginning of the loop ...
	open (LOG, ">>", "$fLog");
	printf LOG ("Query of %s on date: %s", $_, `/bin/date`);
	printf LOG ("\tUptime: %s\n", $qUptime);
	printf LOG ("\tVendor: %s\n", $qVendor);
	printf LOG ("\tSystem Name: %s\n", $qSysName);
	printf LOG ("\tSerial Number: %s\n", $qSerial);
	printf LOG ("\tPage Count: %d\n", $qPageCount);
	printf LOG ("==================================================\n");
	close LOG;

	open(LOG, ">>", "$fCSV");
	printf LOG ("%d,%s,%s,%s,%s,%d\n", $jDay, $_, $qVendor, $qSysName, $qSerial, $qPageCount);
	close LOG;

} # close while()

################################################################################
################################################################################
#####                                                                      #####
##### SUB-FUNCTIONS BELOW HERE ... NOTHING TO WORRY ABOUT                  #####
#####                                                                      #####
################################################################################
################################################################################
sub pingTest {
	my ($ping) = @_;
	my ($rCode);
	
	system(sprintf("ping -q -n -c 1 %s>/dev/null", $ping));
	$rCode = $? >> 8;
	print " ++ in pingTest returning $rCode from $ping ...\n";
	return $rCode;
} # close pintTest()

##*********************************************************##
## return 1 if we are after the leap day in a leap year    ##
##*********************************************************##
sub leapDay {
	my($year,$month,$day) = @_;
	if ($year % 4) {
		return(0);
	}
	if (!($year % 100)) {	# years that are multiples of 100
		if ($year % 400) {	# are not leap years unless they are
			return(0);		# multiples of 400 as well
		}
	}
	if ($month < 2) {
		return(0);
	} elsif (($month == 2) && ($day < 29 )) {
		return(0);
	} else {
		return(1);
	}
} # close leapDay()

##*********************************************************##
## pass in the date, in seconds, of the day you want the   ##
## julian date for. If your localtime() returns the year   ##
## day return that, otherwise figure out the julian date   ##
##*********************************************************##
sub julianDate {
	my($dateInSeconds) = @_;
	my($sec, $min, $hour, $mday, $mon, $year, $wday, $yday);
	
	($sec, $min, $hour, $mday, $mon, $year, $wday, $yday) = localtime($dateInSeconds);
	
	if (defined($yday)) {
		return($yday+1);
	} else {
		return($theJulianDate[$mon] + $mday + &leadDay($year,$mon,$mday));
	}
} # close julianDate()
