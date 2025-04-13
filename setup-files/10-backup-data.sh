#!/bin/bash
# Basic Docker Volume Backup Script

set -eo pipefail

BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# --- Volumes to Backup --- 
# Format: "volume_name:mount_point_in_temp_container"
# Mount point should typically be descriptive of the data
VOLUMES_TO_BACKUP=(
    "n8n_postgres_data:/pgdata"      # PostgreSQL data for n8n
    "n8n_data:/n8n_userdata"         # n8n user configuration/data
    "flowise_data:/flowise_db"       # Flowise database/data
    "qdrant_storage:/qdrant_storage" # Qdrant vector storage
    "n8n_redis_data:/redis_data"     # Redis data for n8n
    "caddy_data:/caddy_data_mount"   # Caddy data (SSL certs, etc.)
    "caddy_config:/caddy_config_mount" # Caddy configuration
    # Add other volumes here if needed, e.g., for Crawl4AI if it uses persistent volumes
)

# --- Script Logic --- 

mkdir -p "$BACKUP_DIR"
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Error: Failed to create backup directory $BACKUP_DIR" >&2
    exit 1
fi

echo "Starting backup process at $(date)"
echo "Target directory: $BACKUP_DIR"

# --- !!! IMPORTANT: Stop containers for data consistency (Recommended) !!! ---
echo "Stopping relevant services for consistent backup..."
sudo docker compose -f /opt/n8n-docker-compose.yaml down || echo "Warning: Failed to stop n8n stack. Backup might be inconsistent."
sudo docker compose -f /opt/flowise-docker-compose.yaml down || echo "Warning: Failed to stop Flowise stack. Backup might be inconsistent."
sudo docker compose -f /opt/qdrant-docker-compose.yaml down || echo "Warning: Failed to stop Qdrant stack. Backup might be inconsistent."
sudo docker compose -f /opt/crawl4ai-docker-compose.yaml down || echo "Warning: Failed to stop Crawl4AI stack (if it exists/uses volumes). Backup might be inconsistent."
# Add other compose files if they manage volumes included in VOLUMES_TO_BACKUP
echo "Services stopped. Waiting a few seconds..."
sleep 10 # Give containers time to shut down gracefully
# --- End Stop Section ---


for item in "${VOLUMES_TO_BACKUP[@]}"; do
    VOLUME_NAME="${item%%:*}"
    MOUNT_POINT="${item#*:}"
    # Try to create a reasonable service name from volume name
    SERVICE_NAME=$(echo "$VOLUME_NAME" | sed -e 's/_data$//' -e 's/_storage$//' -e 's/_db$//' -e 's/_userdata$//')
    BACKUP_FILENAME="${SERVICE_NAME}_${DATE}.tar.gz"
    BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILENAME}"

    echo "-"
    echo "Backing up volume: '$VOLUME_NAME' as '$BACKUP_FILENAME' ..."

    if ! sudo docker volume inspect "$VOLUME_NAME" > /dev/null 2>&1; then
        echo "  Warning: Volume '$VOLUME_NAME' not found. Skipping." 
        continue
    fi

    # Use a temporary alpine container to create a compressed tarball of the volume
    start_time=$(date +%s)
    sudo docker run --rm \
        -v "${VOLUME_NAME}:${MOUNT_POINT}:ro" \
        -v "${BACKUP_DIR}:/backup" \
        alpine \
        tar czf "/backup/${BACKUP_FILENAME}" -C "${MOUNT_POINT}" . 

    if [ $? -eq 0 ]; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo "  Success: Volume '$VOLUME_NAME' backed up to '$BACKUP_PATH' in ${duration}s."
    else
        echo "  Error: Failed to back up volume '$VOLUME_NAME'. Check Docker permissions and volume status." >&2
        # Optional: exit on first error
        # exit 1 
    fi
done

echo "-"

# --- !!! IMPORTANT: Restart containers if they were stopped !!! ---
echo "Restarting services..."
sudo docker compose -f /opt/n8n-docker-compose.yaml up -d || echo "ERROR: Failed to restart n8n stack!"
sudo docker compose -f /opt/flowise-docker-compose.yaml up -d || echo "ERROR: Failed to restart Flowise stack!"
sudo docker compose -f /opt/qdrant-docker-compose.yaml up -d || echo "ERROR: Failed to restart Qdrant stack!"
sudo docker compose -f /opt/crawl4ai-docker-compose.yaml up -d || echo "ERROR: Failed to restart Crawl4AI stack!"
# Add other compose files corresponding to the 'down' commands above
echo "Services restarting. It might take a moment for them to be fully available."
# --- End Restart Section ---


# --- Optional: Cleanup old backups --- 
# Keep backups for the last 7 days
KEEP_DAYS=7
echo "Cleaning up backups older than $KEEP_DAYS days in $BACKUP_DIR ..."
find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +$KEEP_DAYS -print -delete
echo "Cleanup complete."
# ------

echo "Backup process finished at $(date)"

exit 0
