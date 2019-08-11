#!/usr/bin/env bash

#
# based on https://www.sandflysecurity.com/blog/using-linux-utmpdump-for-forensics-and-detecting-log-file-tampering/
# article for reviewing [b|u|w]tmp files to see if they were tampered with

#
# like Colour
#
RED=`echo -e "\033[31m"`
LCYAN=`echo -e "\033[36m"`
YELLOW=`echo -e "\033[33m"`
GREEN=`echo -e "\033[32m"`
BLUE=`echo -e "\033[34m"`
NORMAL=`echo -e "\033[m"`

VERSION="0.1"
AUTHOR="todd fencl"
header() {
  clean
  echo -e """
----------------------------------------
Check [b|u|w]tmp for null'd entries
Run Date: ${GREEN}$(date +%d-%b-%Y\ %H:%M)${NORMAL}
Version: ${YELLOW}${VERSION}${NORMAL} by: ${AUTHOR}
----------------------------------------\n"""
}

main() {
  if [ ! -x /usr/bin/utmpdump ]; then
    echo -e "${RED}[!!]${NORMAL} -- missing utmpdump utility"
    exit 1
  fi

  # check if utmp exists
  if [ -f "/var/run/utmp" ]; then
    echo -e "----------\nChecking ${LCYAN}UTMP${NORMAL}"
    /usr/bin/utmpdump /var/run/utmp | grep "\[0\]/*1970-01-01"
  else
    echo -e "${RED}[!!]${NORMAL} -- missing /var/run/utmp file"
  fi

  # check if wtmp exists
  if [ -f "/var/log/wtmp" ]; then
    echo -e "----------\nChecking ${LCYAN}WTMP${NORMAL}"
    /usr/bin/utmpdump /var/log/wtmp | grep "\[0\]/*1970-01-01"
  else
    echo -e "${RED}[!!]${NORMAL} -- missing /var/log/wtmp file"
  fi

  # check if btmp exists
  if [ -f "/var/log/btmp" ]; then
    echo -e "----------\nChecking ${LCYAN}BTMP${NORMAL}"
    /usr/bin/utmpdump /var/log/btmp | grep "\[0\]/*1970-01-01"
  else
    echo -e "${RED}[!!]${NORMAL} -- missing /var/log/btmp file"
  fi
}

header
main
