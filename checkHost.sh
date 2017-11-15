#!/bin/bash


if [[ $# -eq 0 ]] ;
 then
   echo "No arguement, pass in host name"
   exit 1
fi

sNow="$(/bin/date +%d%b%y\ %H:%H:%S)"
sLook="$(nslookup $1 | grep ^Nam -A1 | awk '{print $2}')"
sPing="$(ping -c 3 $1 &> /dev/null && echo success || echo fail)"

echo "HOSTNAME: $(/bin/hostname)" >> ~/checkHost.log
echo "RUN TIME: ${sNow}" >> ~/checkHost.log
echo "NSLOOKUP: ${sLook}" >> ~/checkHost.log
echo "PING STATUS: ${sPing}" >> ~/checkHost.log
echo "" >> ~/checkHost.log
