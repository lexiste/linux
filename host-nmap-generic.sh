#!/usr/bin/env bash

#
# nmap vulners module used to help identify any known vulns and corresponding cvss scores
# https://nmap.org/nsedoc/scripts/vulners.html
#

NC='\e[0m' #reset
ALRT='\e[97m\e[41m' #white fg / red bg
GOOD='\e[92m' #green fg / no bg (default)

file=$1

if ! [ -r "$file" ]
then
  echo -e "${ALRT}argument not passed, or file not readable${NC}\nformat of file is \`hostname port\`"
  exit 2
fi

while IFS=' ' read line || [[ -n "$line" ]]; do
   split_me=( $line )
   rHost="${split_me[0]}"
   rPort="${split_me[1]}"
#   echo "checking: $rHost:$rPort"

   case $rPort in
      20|21|69|989|990)
        echo -e "${GOOD}[+]${NC} $rHost FTP/SFTP/FTPS checks"
        nmap -p $rPort -sV -Pn --script vulners,ftp* --host-timeout 10m --script-timeout 5m -oN $rHost-$rPort-$(date +%d%b).txt  $rHost
        ;;
      22)
        echo -e "${GOOD}[+]${NC} $rHost SSH checks"
        nmap -p $rPort -sV -Pn --script vulners,ssh2-enum-algos,default --host-timeout 10m --script-timeout 5m -oN $rHost-$rPort-$(date +%d%b).txt $rHost
        ;;
      53)
        echo -e "${GOOD}[+]${NC} $rHost DNS checks and request zone transfer for gsiccorp.net domain"
        nmap -p $rPort -sV -Pn --script vulners,dns-cache-snoop,dns-zone-transfer --script-args dns-zone-transfer.domain=gsiccorp.net --host-timeout 3m --script-timeout 3m -oN $rHost-$rPort-$(date +%d%b).txt $rHost
        ;;
      80|443|8080|8443)
        echo -e "${GOOD}[+]${NC} $rHost limited HTTP(S) checks"
        nmap -p $rPort -sV -Pn --script vulners,ssl-enum-ciphers,http-apache*,http-brute,http-enum,http-headers,http-iis*,http-screenshot -Pn --version-intensity=5 --script-timeout 10m -oN $rHost-$rPort-$(date +%d%b).txt $rHost
        ## --host-timeout 10m http-bigip-cookie,http-errors,
        ;;
      389|636)
        echo -e "${GOOD}[+]${NC} $rHost LDAP checks"
        echo -e "${ALRT}[!!]${NC} LDAP checking needs tuning, may not provide all information"
        nmap -p $rPort -sV -Pn --script vulners,ldap* --script-timeout 3m  -Pn -Sv -oN $rHost-$rPort-$(date +%d%b).txt $rHost
        ;;
      *)
        echo -e "${ALRT}[!!]${NC} undefined port to check, please update case statement with port '$rPort' and query options"
        ;;
   esac

done < "$file"
