#!/bin/bash

# Periodically updates Duck DNS' domain current IP if ec2 public IP has changed.
# Based on https://www.duckdns.org/install.jsp#ec2

domains=$DUCKDNS_DOMAIN
token=$DUCKDNS_TOKEN
interval="${DUCKDNS_INTERVAL:-5m}"

current=""

while true; do
	latest=`ec2-metadata --public-ipv4`
	
	echo "$(date --rfc-3339=seconds) | Public IPv4: $latest"

	if [ "$current" == "$latest" ]
	then
		echo "$(date --rfc-3339=seconds) | IP not changed"
	else
		echo "$(date --rfc-3339=seconds) | IP has changed - updating"
		current=$latest
		echo url="https://www.duckdns.org/update?domains=$domains&token=$token&ip=" | curl -k -o ~/duckdns/duck.log -K -
	fi

	sleep $interval
done
