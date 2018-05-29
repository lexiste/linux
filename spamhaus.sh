#!/bin/bash

##
## script to load the spamhaus DROP file into iptables firewall rules
## should not be done less than 12hr, every 24hr is fine for this
##
## see for info: https://iplists.firehol.org/?ipset=spamhaus_drop
##
## complete replacement for cron job(s) and processing ...
## just run this script from crontab, no need to check for a file, we'll download
##  and save to ~/DROP/
##

folder=~/DROP
droplist="$folder/spamhaus-drop"

echo "source folder: $folder"
echo "drop file: $droplist"

if [ ! -d $folder ]; then 
   echo "drop does not exist!"
   echo "creating folder"
   mkdir -p $folder
fi

if [ -f $droplist ]; then
   mv $droplist $droplist.$(date +%d%b)
   echo "move $droplist to $droplist.$(date +%d%b)"
fi

wget --timeout=20 --quiet -O $droplist https://spamhaus.org/drop/drop.lasso

if [ ! -s "$droplist" ]; then
   echo "unable to find drop list file $droplist " >&2
   echo "perhaps do: wget https://spamhaus.org/drop/drop.lasso -O $droplist"
   exit 1
fi

if [ ! -x /sbin/iptables ]; then
   echo "missing iptables command line tool, exiting" >&2
   exit 1
fi

## first, delete all rules, delete any chains and reset to "accept all"
##  this is semi-dangerous since anything other than spamhuas will be reloaded
##  in a prod world creating a backup, or configuration of other needed (ie. required)
##  rules would be in another file to be loaded as well
##  (EX: block telnet in/out, whitelist known hosts, etc.)
echo "purging previous iptables rules..."
/sbin/iptables -P INPUT ACCEPT
/sbin/iptables -P FORWARD ACCEPT
/sbin/iptables -P OUTPUT ACCEPT
/sbin/iptables -t nat -F
/sbin/iptables -t mangle -F
/sbin/iptables -F
/sbin/iptables -X

exit 1
## looks like we have the input file and iptables located
echo "loading $droplist into iptables..."
cat "$droplist" \
 | sed -e 's/;.*//' \
 | grep -v '^ *$' \
 | while read singleBlock ; do
   /sbin/iptables -I INPUT -s "$singleBlock" -j DROP
   /sbin/iptables -I OUTPUT -d "$singleBlock" -j DROP
   /sbin/iptables -I FORWARD -s "$singleBlock" -j DROP
   /sbin/iptables -I FORWARD -d "$singleBlock" -j DROP
done
