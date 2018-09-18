#!/bin/bash

## simple script to show the changing differences in the iptables command to 
## catch incrementing counters / changes to the rules since we are using
## verbose output; display updates every 1 second

while true; do iptables -nvL > /tmp/now; diff -U0 /tmp/prev /tmp/now > /tmp/diff; clear; tail /tmp/diff; mv -f /tmp/now /tmp/prev; sleep 1; done
