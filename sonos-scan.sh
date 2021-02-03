#!/bin/bash
#
# Sonos - Telegraf Host Disovery for Sonos
#
# sonos-scan.sh <hostname>
#
# Uses NMAP to scan for Sonos Devices on your network (anything that responds to port 1400)
#
# Dave Schmid, dave@pulpfree.org
#
# version 0.2
# 2021-02-03

if [ -n "$1" ]; then

  SUBNET=$1
  echo "Subnet provided. Using ${SUBNET}"

else

  SUBNET=$(ip route | awk '/proto/ && !/default/ {print $1}' |head -1)
  echo "First parameter not supplied. Using discovered subnet ${SUBNET}"

fi

echo "Using NMAP to scan for Sonos Devices"

nmap -p 1400 "${SUBNET}" --open -oG - | grep "/open" | awk '{ print $3 }' | sed 's/[(]//g' | sed 's/[)]//g' > /tmp/sonos_hosts.txt

echo '[[inputs.exec]]' > ./telegraf.d/sonos.conf
echo '  commands = [' >> ./telegraf.d/sonos.conf

for i in `cat /tmp/sonos_hosts.txt`; do

echo "Found $i"

echo '"bash /etc/telegraf/sonos-exporter.sh '$i'",' >> ./telegraf.d/sonos.conf

done

echo '  ]' >> ./telegraf.d/sonos.conf
echo ' '
echo '  timeout = "10s"' >> ./telegraf.d/sonos.conf
echo '  data_format = "influx"' >> ./telegraf.d/sonos.conf

rm /tmp/sonos_hosts.txt
