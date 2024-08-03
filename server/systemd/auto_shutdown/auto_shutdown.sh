#!/bin/bash

# Shutdowns instance if docker compose stack is not running

running=$(docker compose -f ${data_mount_path}/docker-compose.yml ps -q ${compose_main_service_name})

if [ -z "$running" ]; then
  echo "Compose service not running, shutting down"
  sudo shutdown -h now "GameServerEC2Discord auto shutdown"
else
  echo "Compose service still running: $running"
fi
