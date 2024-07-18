#!/bin/bash

# Periodically updates Duck DNS' domain with latest IPv4, if the IP has changed.
# Based on https://www.duckdns.org/install.jsp#ec2

domains=${duckdns_domain}
token=${duckdns_token}
interval=1m

current=""

while true; do
	latest=`ec2-metadata --public-ipv4`
	
	echo "Latest public IPv4: $latest"

	if [ "$current" == "$latest" ]
	then
		echo "IP not changed"
	else
		echo "IP has changed - updating"
		current=$latest
		curl -sS -k "https://www.duckdns.org/update?domains=$domains&token=$token&ip="
	fi

	echo "Waiting $interval"
	sleep $interval
done
