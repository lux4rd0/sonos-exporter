#!/bin/bash
#
# Sonos - Network Bandwidth Usage
#
# sonos-exporter.sh <hostname>
#
# Provide a Sonos speaker URL and Network Interface and it returns RX and TX metrics, usable as a Cacti script
#
# Dave Schmid, dave@pulpfree.org
#
# version 0.2
# 2020-05-20
# version 0.1
# 2017-10-21
#

# ./sonos-exporter.sh sonos-office-sub

HOSTNAME=$1
IPADDRESS=$(getent hosts "${HOSTNAME}" | awk '{ print $1 }')
URL_STATUS="http://${IPADDRESS}:1400/status/zp"
URL_NETWORK="http://${IPADDRESS}:1400/status/ifconfig"

sonos_status=$(curl -s -m 5 "${URL_STATUS}")
sonos_ifconfig=$(curl -s -m 5 "${URL_NETWORK}")

# Sonos Status

ZoneName=$(<<< "${sonos_status}" grep -oPm1 "(?<=<ZoneName>)[^<]+" | sed 's/ /\\ /g' | sed 's/,/\\,/g')
SoftwareVersion=$(<<< "${sonos_status}" grep -oPm1 "(?<=<SoftwareVersion>)[^<]+")
SerialNumber=$(<<< "${sonos_status}" grep -oPm1 "(?<=<SerialNumber>)[^<]+")
SoftwareVersion=$(<<< "${sonos_status}" grep -oPm1 "(?<=<SoftwareVersion>)[^<]+")
HardwareVersion=$(<<< "${sonos_status}" grep -oPm1 "(?<=<HardwareVersion>)[^<]+")
SeriesID=$(<<< "${sonos_status}" grep -oPm1 "(?<=<SeriesID>)[^<]+")
IPAddress=$(<<< "${sonos_status}" grep -oPm1 "(?<=<IPAddress>)[^<]+")

# Sonos Interface Details

for interface in apcli0 ath0 ath1 br0 eth0 eth1 lo ra0; do

# RX

rxBytes=$(<<< "${sonos_ifconfig}" grep -A 7 "${interface}" |grep "RX bytes:" | awk '{print $2,$6;}' | sed -n 1p | sed 's/bytes://g' | awk '{print $1}')
rxPackets=$(<<< "${sonos_ifconfig}" grep -A 7 "${interface}" |grep "RX packets:" | awk '{print $2,$3,$4,$5,$6;}' | sed 's/:/ /g' |awk '{print $2}')
rxErrors=$(<<< "${sonos_ifconfig}" grep -A 7 "${interface}" |grep "RX packets:" | awk '{print $2,$3,$4,$5,$6;}' | sed 's/:/ /g' |awk '{print $4}')
rxDropped=$(<<< "${sonos_ifconfig}" grep -A 7 "${interface}" |grep "RX packets:" | awk '{print $2,$3,$4,$5,$6;}' | sed 's/:/ /g' |awk '{print $6}')
rxOverruns=$(<<< "${sonos_ifconfig}" grep -A 7 "${interface}" |grep "RX packets:" | awk '{print $2,$3,$4,$5,$6;}' | sed 's/:/ /g' |awk '{print $8}')
rxFrame=$(<<< "${sonos_ifconfig}" grep -A 7 "${interface}" |grep "RX packets:" | awk '{print $2,$3,$4,$5,$6;}' | sed 's/:/ /g' |awk '{print $10}')

# TX

txBytes=$(<<< "${sonos_ifconfig}" grep -A 7 "${interface}" |grep "RX bytes:" | awk '{print $2,$6;}' | sed -n 1p | sed 's/bytes://g' | awk '{print $2}')
txPackets=$(<<< "${sonos_ifconfig}" grep -A 7 "${interface}" |grep "TX packets:" | awk '{print $2,$3,$4,$5,$6;}' | sed 's/:/ /g' |awk '{print $2}')
txErrors=$(<<< "${sonos_ifconfig}" grep -A 7 "${interface}" |grep "TX packets:" | awk '{print $2,$3,$4,$5,$6;}' | sed 's/:/ /g' |awk '{print $4}')
txDropped=$(<<< "${sonos_ifconfig}" grep -A 7 "${interface}" |grep "TX packets:" | awk '{print $2,$3,$4,$5,$6;}' | sed 's/:/ /g' |awk '{print $6}')
txOverruns=$(<<< "${sonos_ifconfig}" grep -A 7 "${interface}" |grep "TX packets:" | awk '{print $2,$3,$4,$5,$6;}' | sed 's/:/ /g' |awk '{print $8}')
txFrame=$(<<< "${sonos_ifconfig}" grep -A 7 "${interface}" |grep "TX packets:" | awk '{print $2,$3,$4,$5,$6;}' | sed 's/:/ /g' |awk '{print $10}')

# collisions txqueuelen

collisions=$(<<< "${sonos_ifconfig}" grep -A 7 "${interface}" |grep "collisions" | awk '{print $1,$2}' | sed 's/:/ /g' | awk '{print $2}')
txqueuelen=$(<<< "${sonos_ifconfig}" grep -A 7 "${interface}" |grep "collisions" | awk '{print $1,$2}' | sed 's/:/ /g' | awk '{print $4}')

if [ -n "${rxBytes}" ]; then

echo "sonos_status,host=${HOSTNAME},ZoneName=${ZoneName},SerialNumber=${SerialNumber},HardwareVersion=${HardwareVersion},SeriesID=${SeriesID},IPAddress=${IPAddress},SoftwareVersion=${SoftwareVersion},interface=${interface} rxBytes=${rxBytes},txBytes=${txBytes},rxPackets=${rxPackets},rxErrors=${rxErrors},rxDropped=${rxDropped},rxOverruns=${rxOverruns},rxFrame=${rxFrame},txPackets=${txPackets},txErrors=${txErrors},txDropped=${txDropped},txOverruns=${txOverruns},txFrame=${txFrame},collisions=${collisions},txqueuelen=${txqueuelen}"

fi

done
