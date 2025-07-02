#!/bin/bash

pushd "/opt/clipboard/" || exit

# Podman or Docker Compose file location
COMPOSE_FILE_PATH="./docker-compose.yaml"

# Check all services defined in Compose file
RUNNING_CONTAINERS=$(podman ps --format "{{.Names}}" | grep -f <(podman-compose -f "$COMPOSE_FILE_PATH" config --services))
TOTAL_SERVICES=$(podman-compose -f "$COMPOSE_FILE_PATH" config --services | wc -l)

# If the number of running containers is less than expected, restart
if [ "$(echo "$RUNNING_CONTAINERS" | wc -l)" -lt "$TOTAL_SERVICES" ]; then
    echo "$(date): Some containers are not running! Restarting all..."
    podman-compose -f "$COMPOSE_FILE_PATH" up -d
else
    echo "$(date): All containers are running."
fi

popd || exit
