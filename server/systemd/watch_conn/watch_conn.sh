#!/bin/bash

# We can't use netstat or ss, see https://unix.stackexchange.com/a/758008/617433
command="sudo conntrack -L --dst-nat | grep -w ${main_port} | grep -E 'ASSURED|ESTABLISHED' -w -c"

# Sleep to avoid shutting down right after container start
interval=1m
no_conn_count=0
max_count=10

while [[ $no_conn_count -lt $max_count ]]; do
    echo "no_conn_count: $no_conn_count / $max_count"

    if [[ $(eval $command) -ne "0" ]]; then
        echo "Established connection found, resetting count"
        (( no_conn_count = 0 ))
    else
        (( no_conn_count++ ))
    fi;

    sleep $interval
done

echo "There has been no established connections for 10min. Stopping compose at ${data_mount_path}"
docker compose -f ${data_mount_path}/docker-compose.yml down
exit 0;