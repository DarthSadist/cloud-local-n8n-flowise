#!/bin/bash

# This script creates the necessary Docker volumes for the application stack.

echo "Creating Docker volumes..."

VOLUMES=(
    "n8n_data"
    "n8n_postgres_data" # Consistent name for postgres
    "n8n_redis_data"    # Consistent name for redis
    "flowise_data"
    "qdrant_storage"    # Consistent name for qdrant
    "caddy_data"
    "caddy_config"
    "n8n_user_files"    # Added from 03b
    "wordpress_data"    # For WordPress files
    "wordpress_db_data" # For WordPress database
    "waha_sessions"     # For Waha WhatsApp sessions
    "waha_media"        # For Waha media files
    "mem0_data"         # For Mem0 data storage
)

FAILED_VOLUMES=0

for VOL_NAME in "${VOLUMES[@]}"; do
    if ! sudo docker volume inspect "$VOL_NAME" > /dev/null 2>&1; then
        echo "Creating volume: $VOL_NAME"
        sudo docker volume create "$VOL_NAME"
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to create volume $VOL_NAME" >&2
            FAILED_VOLUMES=$((FAILED_VOLUMES + 1))
        fi
    else
        echo "Volume $VOL_NAME already exists."
    fi
done

if [ $FAILED_VOLUMES -ne 0 ]; then
    echo "ERROR: Failed to create $FAILED_VOLUMES volume(s). Please check Docker permissions and logs." >&2
    exit 1
fi

echo "✅ Docker volumes checked/created successfully."
exit 0
