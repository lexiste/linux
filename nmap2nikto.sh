#!/bin/bash

## what ports to look for
ports="80 443 8080 8443"
curdate=$(date +%Y-%d-%m)

## for a massive, external audit of Radial with multiple /24 and /23 blocks, masscan should be used to generate the 
##  targets file ... and we have a built configuration file (radial-mass.confi) that includes out net blocks and 
##  other configuration data.
##
## something as simple as the following could be used: (just check the radial-mass.conf file for the correct ports defined)
#$ masscan -c ~/pentest/radial-mass.conf | awk '{print $6}' > targets.lst

## take the file targets.lst as input for the initial nmap scan
##  by default, nmap scans the top 1,000 ports including the most common alternate web ports (8080, 8443, etc)
nmap -T3 -n -Pn -iL targets.lst -oA $curdate\_nmap_scan --reason

## now loop through the ports, checking the nmap output and run the nikto scan
for testport in $ports
   do for targetip in $(awk '/'$testport'\/open/ {print $2}' $curdate\_nmap_scan.gnmap)
      ## don't prompt for any response; save requests/responses in a dynamic folder; and tune to only look for specific 
      ##  data, don't perform a full category scan; provide a valid, generic user agent; format output to HTML and save
      ##  in format YYYY-DD-MM_nikto_IP_PORT.html
      do nikto -host $targetip:$testport -ask no -nointeractive -Save . -Tuning 23489b -useragent "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1" -Format htm -output $curdate\_nikto_$targetip\_$testport.html
   done
done
