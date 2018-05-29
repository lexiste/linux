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
NC='\e[0m' #reset
ALRT='\e[97m\e[41m' #white fg / red bg
GOOD='\e[92m' #green fg / no bg (default)

echo -e "source folder: $folder"
echo -e "drop file: $droplist"

if [ ! -d $folder ]; then 
   echo -e "drop does not exist!"
   echo -e "${ALRT}creating folder${NC}"
   mkdir -p $folder
fi

if [ -f $droplist ]; then
   mv --force $droplist $droplist.$(date +%d%b)
   echo -e "move ${GOOD}$droplist${NC} to ${GOOD}$droplist.$(date +%d%b)${NC}"
fi

wget --timeout=20 --quiet -O $droplist https://spamhaus.org/drop/drop.lasso

if [ ! -s "$droplist" ]; then
   echo -e "${ALRT}unable to find drop list file $droplist${NC} " >&2
   echo -e "perhaps do: wget https://spamhaus.org/drop/drop.lasso -O $droplist"
   exit 1
fi

if [ ! -x /sbin/iptables ]; then
   echo -e "${ALRT}missing iptables command line tool, exiting${NC}" >&2
   exit 1
fi

## first, delete all rules, delete any chains and reset to "accept all"
##  this is semi-dangerous since anything other than spamhuas will be reloaded
##  in a prod world creating a backup, or configuration of other needed (ie. required)
##  rules would be in another file to be loaded as well
##  (EX: block telnet in/out, whitelist known hosts, etc.)
echo -e "${GOOD}purging previous iptables rulesi${NC}..."
/sbin/iptables -P INPUT ACCEPT
/sbin/iptables -P FORWARD ACCEPT
/sbin/iptables -P OUTPUT ACCEPT
/sbin/iptables -t nat -F
/sbin/iptables -t mangle -F
/sbin/iptables -F
/sbin/iptables -X

## looks like we have the input file and iptables located
echo -e "${GOOD}loading $droplist into iptables${NC}..."
cat "$droplist" \
 | sed -e 's/;.*//' \
 | grep -v '^ *$' \
 | while read singleBlock ; do
   /sbin/iptables -I INPUT -s "$singleBlock" -j DROP
   /sbin/iptables -I OUTPUT -d "$singleBlock" -j DROP
   /sbin/iptables -I FORWARD -s "$singleBlock" -j DROP
   /sbin/iptables -I FORWARD -d "$singleBlock" -j DROP
done
