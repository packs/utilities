#!/bin/bash

for host in $(ls -d1 /sys/class/scsi_host/host*)
do
  echo "- - -" > ${host}/scan
done
