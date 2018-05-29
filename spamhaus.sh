#!/bin/bash

#
# script to load the spamhaus DROP file into iptables firewall rules
# should not be done less than 12hr, every 24hr is fine for this
#
# see for info: https://iplists.firehol.org/?ipset=spamhaus_drop

if [ -n "$1" ]; then
   droplist="$1"
else
   echo "no file present, provide file as option"
   exit 1
fi

if [ ! -s "$droplist" ]; then
   echo "unable to find drop list file $droplist " >&2
   echo "perhaps do: wget https://spamhaus.org/drop/drop.lasso -O $droplist"
   exit 1
fi

if [ ! -x /sbin/iptables ]; then
   echo "missing iptables command line tool, exiting" >&2
   exit 1
fi

# first, delete all rules, delete any chains and reset to "accept all"
#  this is semi-dangerous since anything other than spamhuas will be reloaded
#  in a prod world creating a backup, or configuration of other needed (ie. required)
#  rules would be in another file to be loaded as well
#  (EX: block telnet in/out, whitelist known hosts, etc.)
/sbin/iptables -P INPUT ACCEPT
/sbin/iptables -P FORWARD ACCEPT
/sbin/iptables -P OUTPUT ACCEPT
/sbin/iptables -t nat -F
/sbin/iptables -t mangle -F
/sbin/iptables -F
/sbin/iptables -X

# looks like we have the input file and iptables located
cat "$droplist" \
 | sed -e 's/;.*//' \
 | grep -v '^ *$' \
 | while read singleBlock ; do
   /sbin/iptables -I INPUT -s "$singleBlock" -j DROP
   /sbin/iptables -I OUTPUT -d "$singleBlock" -j DROP
   /sbin/iptables -I FORWARD -s "$singleBlock" -j DROP
   /sbin/iptables -I FORWARD -d "$singleBlock" -j DROP
done
