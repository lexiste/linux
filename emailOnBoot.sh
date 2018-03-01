#!/bin/bash
#
### BEGIN INIT INFO
# Provides:          emailOnBoot
# Required-Start:    hostname $network
# Required-Stop:
# Should-Start:
# Default-Start:     1 2 3 4 5
# Default-Stop:
# Short-Description: Send email when the device rebots
# Description:       When this device restarts, collect
#                    some information and send it over to my
#                    gmail account.
### END INIT INFO

if [ -f /etc/no-email-on-boot ]; then
   echo "I will not send email since no-email-on-boot exists..."
   exit 0
fi

##
LINE="======================================================================"

echo "Host $(hostname) booted at $(date)
$LINE
Updated Needed
$( /usr/bin/apt-get upgrade --simulate && echo "No updates appear to be needed" )

$LINE
Network Information
$( [[ -x /sbin/ifconfig ]] && /sbin/ifconfig -a || echo "ifconfig not found" )

$LINE
Local IP Addresses
$( /sbin/ip -4 addr show )

$LINE
Routing Information
$( /bin/netstat -er )

$LINE
$( /sbin/ip route show )

$LINE
ARP Table
$( /usr/sbin/arp -e )

$LINE
Memory
$( /usr/bin/free )

$LINE
System Information (dmidecode)
$( dmidecode )" | mail -s "System Startup $( hostname )" todd.fencl@gmail.com