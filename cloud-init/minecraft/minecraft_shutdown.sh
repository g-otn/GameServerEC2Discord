#!/bin/bash

# Shutdowns instance if docker compose stack is not running

running=$(docker compose -f ${minecraft_data_path}/docker-compose.yml ps -q ${minecraft_compose_service_name})

if [ -z "$running" ]; then
  echo "not running, shutting down"
  sudo shutdown -h now
else
  echo "running $running"
fi
