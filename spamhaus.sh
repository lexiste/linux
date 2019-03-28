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

## variables ... we need them
VERSION="0.1"
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"
__srcFolder=~/DROP
__droplist="$__srcFolder/spamhaus-drop"

## Colors ... we love them ...
NC='\e[0m' #reset
ALRT='\e[97m\e[41m' #white fg / red bg
GOOD='\e[92m' #green fg / no bg (default)

header() {
  clear
  echo -e """
----------------------------------------
  Source Folder: ${__srcFolder}
  Drop File: ${__droplist}
----------------------------------------\n"""
}

main() {

  set -o errexit # exit when a command fails
  set -o nounset # exit when script uses an undeclared variable

  if [ ! -d ${__srcFolder} ]; then
     echo -e "drop does not exist!"
     echo -e "${ALRT}creating Source Folder (${__srcFolder})${NC}"
     mkdir -p ${__srcFolder}
  fi

  if [ -f ${__droplist} ]; then
     mv --force ${__droplist} ${__droplist}.$(date +%d%b)
     echo -e "move ${GOOD}${__droplist}${NC} to ${GOOD}${__droplist}.$(date +%d%b)${NC}"
  fi

  wget --timeout=20 --quiet -O ${__droplist} https://www.spamhaus.org/drop/drop.lasso

  if [ ! -s "${__droplist}" ]; then
     echo -e "${ALRT}unable to find drop list file ${__droplist}${NC} " >&2
     echo -e "perhaps do: wget https://www.spamhaus.org/drop/drop.lasso -O ${__droplist}"
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
  echo -e "${GOOD}purging${NC} previous iptables rules..."
  /sbin/iptables -P INPUT ACCEPT
  /sbin/iptables -P FORWARD ACCEPT
  /sbin/iptables -P OUTPUT ACCEPT
  /sbin/iptables -t nat -F
  /sbin/iptables -t mangle -F
  /sbin/iptables -F
  /sbin/iptables -X

  ## looks like we have the input file and iptables located
  echo -e "${GOOD}loading${NC} ${__droplist} into iptables..."
  cat "${__droplist}" \
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
