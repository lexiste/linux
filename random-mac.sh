#!/usr/bin/env bash

set -o errexit
set -o nounset
if [ $# == 0 ]; then
  echo -e """Reset the MAC address on the given interface\n
  Usage: $0 <interface>\n"""

  exit 1
fi

_iface=$1
/usr/bin/macchanger -s "${_iface}" # show current MAC addr before chaning
/sbin/dhclient -r "${_iface}" # release and stop running DHCP client
/sbin/ifconfig "${_iface}" down # shutdown interface
/usr/bin/macchanger -A "${_iface}" # randomize a new MAC addr on interface
/sbin/ifconfig "${_iface}" up # bring interface up
/sbin/dhclient ${_iface} # request new DHCP address
