#!/usr/bin/env bash

file=$1

if ! [ -r "$file" ]
then
  echo "argument not passed, or file not readable"
  exit 2
fi

while IFS=' ' read line || [[ -n "$line" ]]; do
   split_me=( $line )
   rHost="${split_me[0]}"
   rPort="${split_me[1]}"
#   echo "checking: $rHost:$rPort"

   case $rPort in
      21)
        echo "$rHost ftp checks"
        nmap -p $rPort --script=ftp* -oN $rHost-$rPort-$(date +%d%b).txt -sV --host-timeout 10m --script-timeout 5m $rHost
        ;;
      22)
        echo "$rHost ssh checks"
        nmap -p $rPort --script=ssh2-enum-algos,default -oN $rHost-$rPort-$(date +%d%b).txt -sV --host-timeout 10m --script-timeout 5m  $rHost
        ;;
      80|443|8080|8443)
        echo "$rHost http/s limited checks + screen shot"
        nmap -p $rPort --script=http-apache*,http-bigip-cookie,http-brute,http-enum,http-errors,http-headers,http-iis*,http-wordpress*,http-screenshot -Pn -sV --host-timeout 10m --script-timeout 10m -oN $rHost-$rPort-$(date +%d%b).txt $rHost
        ;;
#      443)
#        echo "https checks"
#        nmap -p $rPort --script=http* -oN $rHost-$rPort-$(date +%d%b).txt -sV --host-timeout 60s --script-timeout 30s $rHost
#        ;;
      *)
        echo "undefined port to check"
        ;;
   esac

done < "$file"
