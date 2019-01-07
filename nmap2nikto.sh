#!/bin/bash

## what ports to look for
ports="80 443 8080 8443"
curdate=$(date +%Y-%d-%m)

<<<<<<< HEAD
## for some output formatting and coloring
NC='\e[0m' ## reset
ALERT='\e[97m\e[41m' ## white fg && red bg
GOOD='\e[92m' ## green fg

echo -e "Running $BASH_SOURCE on $(/bin/hostname) on $(date)"

=======
>>>>>>> f0ba32bf42f1649d8f6d3d4e897672b106917166
## for a massive, external audit of Radial with multiple /24 and /23 blocks, masscan should be used to generate the 
##  targets file ... and we have a built configuration file (radial-mass.confi) that includes our net blocks and 
##  other configuration data.
##
## something as simple as the following could be used: (just check the radial-mass.conf file for the correct ports defined)
<<<<<<< HEAD
## 
## masscan output shows 0/icmp for hosts that reply, filter this out since it is not a port listed this is what the if()
##  statement allows, it will print if col 4 is not 0/icmp
echo -e "+ executing initial host detection using masscan"
masscan -c ~/pentest/radial-mass.conf | awk '{ if ($4 != "0/icmp") print $6}' > targets.lst
## perform some de-dup on the targets file by running through unique but since we can't overwrite the file, write to temp
##  then move it back
## this is due to masscan reporting on each open port, if we find one (1) open port we want to scan using nmap and nikto
unique -inp=targets.lst t.$$; mv t.$$ targets.lst


## take the file targets.lst as input for the initial nmap scan
##  by default, nmap scans the top 1,000 ports including the most common alternate web ports (8080, 8443, etc)
echo -e "+ executing ${GOOD}nmap${NC} scans output to ${GOOD}$curdate\_nmap_scan${NC}"
nmap -T3 -n -Pn -iL targets.lst -oA $curdate\_nmap_scan --reason > /dev/null 2>&1

## now loop through the ports, checking the nmap output and run the nikto scan
echo -e "+ setting up web app scans using ${GOOD}Nikto${NC}"
=======
#$ masscan -c ~/pentest/radial-mass.conf | awk '{print $6}' > targets.lst

## take the file targets.lst as input for the initial nmap scan
##  by default, nmap scans the top 1,000 ports including the most common alternate web ports (8080, 8443, etc)
nmap -T3 -n -Pn -iL targets.lst -oA $curdate\_nmap_scan --reason

## now loop through the ports, checking the nmap output and run the nikto scan
>>>>>>> f0ba32bf42f1649d8f6d3d4e897672b106917166
for testport in $ports
   do for targetip in $(awk '/'$testport'\/open/ {print $2}' $curdate\_nmap_scan.gnmap)
      ## don't prompt for any response; save requests/responses in a dynamic folder; and tune to only look for specific 
      ##  data, don't perform a full category scan; provide a valid, generic user agent; format output to HTML and save
      ##  in format YYYY-DD-MM_nikto_IP_PORT.html
<<<<<<< HEAD
      do nikto -host $targetip -port $testport -ask no -nointeractive -nolookup -Save . -Tuning 23489b -useragent "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1" -Format htm -output $curdate\_nikto_$targetip\_$testport.html
=======
      do nikto -host $targetip:$testport -ask no -nointeractive -Save . -Tuning 23489b -useragent "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1" -Format htm -output $curdate\_nikto_$targetip\_$testport.html
>>>>>>> f0ba32bf42f1649d8f6d3d4e897672b106917166
   done
done
