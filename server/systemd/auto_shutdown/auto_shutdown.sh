#!/bin/bash

# Shutdowns instance if docker compose stack is not running

running=$(docker compose -f ${server_data_path}/docker-compose.yml ps -q ${compose_main_service_name})

if [ -z "$running" ]; then
  echo "Not running, shutting down"
  sudo shutdown -h now
else
  echo "Running $running"
fi
