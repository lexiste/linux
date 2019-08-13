#!/usr/bin/env bash

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
## added support for the Team Cymru bogons blocks as well. Bogons blocking
##  should only ever be placed at the border router to INBOUND traffic
##  (public to private networks)
##
VERSION="0.1"
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"

folder=~/DROP
spamhaus="$folder/spamhaus-drop"
bogons="$folder/bogons-ipv4"
talos="$folder/talos-ioc"

## redirect stdout/stderr to file
exec &> $folder/${0##*/}.log

NC='\e[0m' #reset
ALRT='\e[97m\e[41m' #white fg / red bg
GOOD='\e[92m' #green fg / no bg (default)

header() {
  clear
  echo -e """
----------------------------------------
Run Date: ${GOOD}$(date +%d-%b-%Y\ %H:%M)${NC}
source folder: ${folder}
spamhaus file: ${spamhaus}
bogon file: ${bogons}
talos file: ${talos} [for record keeping]
----------------------------------------\n"""
}

main() {
  if [ ! -d "${folder}" ]; then
     echo -e "${ALRT}[!!] Creating folder ${folder}${NC}"
     mkdir -p ${folder}
  fi

  if [ -f "${spamhaus}" ]; then
    echo -e "move ${GOOD}${spamhaus}${NC} to ${GOOD}${spamhaus}.$(date +%d%b)${NC}"
    mv --force ${spamhaus} ${spamhaus}.$(date +%d%b)
  fi

  if [ -f "${bogons}" ]; then
    echo -e "move ${GOOD}${bogons}${NC} to ${GOOD}${bogons}.$(date +%d%b)${NC}"
    mv --force ${bogons} ${bogons}.$(date +%d%b)
  fi

  if [ -f "${talos}" ]; then
    echo -e "move ${GOOD}${talos}${NC} to ${GOOD}${talos}.$(date +%d%b)${NC}"
    mv --force ${talos} ${talos}.$(date +%d%b)
  fi

  echo ""
  wget --timeout=20 --quiet -O ${spamhaus} https://spamhaus.org/drop/drop.lasso
  echo -e "${GOOD}[+]${NC} downloading ${spamhaus} file"
  wget --timeout=20 --quiet -O ${bogons} https://www.team-cymru.org/Services/Bogons/fullbogons-ipv4.txt
  echo -e "${GOOD}[+]${NC} downloading ${bogons} file"
  wget --timeout=20 --quiet -O ${talos} talos-iocs https://talosintelligence.com/documents/ip-blacklist
  echo -e "${GOOD}[+]${NC} downloading ${talos} file"
  echo ""

  if [ ! -s "${spamhaus}" ]; then
     echo -e "${ALRT}[!!]${NC} unable to find drop list file ${spamhaus}"
     echo -e "perhaps do: wget https://spamhaus.org/drop/drop.lasso -O ${spamhaus}"
     exit 1
  else
     # convert the spamhaus file into a Cisco formated ACL file that c/would be used to update router(s)
     echo -e "converting ${spamhaus} into ACL format files"
     cat ${spamhaus} | grep -v "^;" | awk 'BEGIN {FS=" ; "}; {print $1}' | sed -f ~/scripts/subnet2mask.sed | awk '{ print "deny ip "$1" "$2" any"}' > $spamhaus.in
     cat ${spamhaus} | grep -v "^;" | awk 'BEGIN {FS=" ; "}; {print $1}' | sed -f ~/scripts/subnet2mask.sed | awk '{ print "deny ip any "$1" "$2}' > $spamhaus.out
     echo -e "finished processing ${spamhaus}\n"
  fi

  if [ ! -s "${bogons}" ]; then
     echo -e "${ALRT}[!!]${NC} unable to find the bogons file $bogons"
     echo -e "perhaps a visit to https://www.team-cymru.org/Services/Bogons/fullbogons-ipv4.txt"
     exit 1
  else
     # convert the bogons file into a Cisco formated ACL file that c/would be used to update router(s)
     echo -e "converting ${bogons} into ACL format files"
     cat ${bogons} | grep -v "^#" | sed -f ~/scripts/subnet2mask.sed | awk '{ print "deny ip "$1" "$2" any"}' > $bogons.in
     echo -e "finished processing ${bogons}\n"
  fi

  if [ ! -x /sbin/iptables ]; then
     echo -e "${ALRT}[!!]${NC} missing iptables command line tool, exiting"
     exit 1
  fi

  ## first, delete all rules, delete any chains and reset to "accept all"
  ##  this is semi-dangerous since anything other than spamhuas will be reloaded
  ##  in a prod world creating a backup, or configuration of other needed (ie. required)
  ##  rules would be in another file to be loaded as well
  ##  (EX: block telnet in/out, whitelist known hosts, etc.)
  echo -e "${ALRT}[!!]${NC} purging previous iptables rules..."
  /sbin/iptables -P INPUT ACCEPT
  /sbin/iptables -P FORWARD ACCEPT
  /sbin/iptables -P OUTPUT ACCEPT
  /sbin/iptables -t nat -F
  /sbin/iptables -t mangle -F
  /sbin/iptables -F
  /sbin/iptables -X

  ## looks like we have the input file and iptables located
  echo -e "${GOOD}loading${NC} $spamhaus into iptables..."
  cat "${spamhaus}" \
   | sed -e 's/;.*//' \
   | grep -v '^ *$' \
   | while read singleBlock ; do
     /sbin/iptables -I INPUT -s "$singleBlock" -j DROP
     /sbin/iptables -I OUTPUT -d "$singleBlock" -j DROP
     /sbin/iptables -I FORWARD -s "$singleBlock" -j DROP
     /sbin/iptables -I FORWARD -d "$singleBlock" -j DROP
  done
}

header
main
