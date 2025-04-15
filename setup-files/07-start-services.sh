#!/bin/bash

echo "Starting services..."

# Check if Docker is running
if ! sudo docker info > /dev/null 2>&1; then
    echo "Error: Docker daemon is not running." >&2
    exit 1
fi

# Define compose file paths
N8N_COMPOSE_FILE="/opt/n8n-docker-compose.yaml"
FLOWISE_COMPOSE_FILE="/opt/flowise-docker-compose.yaml"
QDRANT_COMPOSE_FILE="/opt/qdrant-docker-compose.yaml"
CRAWL4AI_COMPOSE_FILE="/opt/crawl4ai-docker-compose.yaml"
WATCHTOWER_COMPOSE_FILE="/opt/watchtower-docker-compose.yaml"
NETDATA_COMPOSE_FILE="/opt/netdata-docker-compose.yaml"
ENV_FILE="/opt/.env" # Assuming .env is copied to /opt

# Check if compose files exist
if [ ! -f "$N8N_COMPOSE_FILE" ]; then
    echo "Error: $N8N_COMPOSE_FILE not found." >&2
    exit 1
fi
if [ ! -f "$FLOWISE_COMPOSE_FILE" ]; then
    echo "Error: $FLOWISE_COMPOSE_FILE not found." >&2
    exit 1
fi
if [ ! -f "$QDRANT_COMPOSE_FILE" ]; then
    echo "Error: $QDRANT_COMPOSE_FILE not found." >&2
    exit 1
fi
if [ ! -f "$CRAWL4AI_COMPOSE_FILE" ]; then
    echo "Error: $CRAWL4AI_COMPOSE_FILE not found." >&2
    exit 1
fi
if [ ! -f "$WATCHTOWER_COMPOSE_FILE" ]; then
    echo "Error: $WATCHTOWER_COMPOSE_FILE not found." >&2
    exit 1
fi
if [ ! -f "$NETDATA_COMPOSE_FILE" ]; then
    echo "Error: $NETDATA_COMPOSE_FILE not found." >&2
    exit 1
fi
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: $ENV_FILE not found." >&2
    exit 1
fi

echo "Starting n8n, Flowise, Qdrant, Adminer, Crawl4AI, Watchtower, Netdata, Caddy, and services via Docker Compose..."

# Start all service stacks, ensuring all containers are up regardless of which compose file they are in

# Start n8n stack (includes Caddy, Postgres, Redis, Adminer if present)
echo "Starting n8n stack (n8n, Caddy, Postgres, Redis, Adminer)..."
sudo docker compose -f "$N8N_COMPOSE_FILE" --env-file "$ENV_FILE" up -d || { echo "Failed to start n8n stack"; exit 1; }

# Wait for network creation
sleep 5
if ! sudo docker network inspect app-network &> /dev/null; then
  echo "ERROR: Failed to create app-network"
  exit 1
fi

# Start Flowise stack
echo "Starting Flowise stack..."
sudo docker compose -f "$FLOWISE_COMPOSE_FILE" --env-file "$ENV_FILE" up -d || { echo "Failed to start Flowise stack"; exit 1; }

# Start Qdrant stack
echo "Starting Qdrant stack..."
sudo docker compose -f "$QDRANT_COMPOSE_FILE" --env-file "$ENV_FILE" up -d || { echo "Failed to start Qdrant stack"; exit 1; }

# Start Crawl4AI stack
echo "Starting Crawl4AI stack..."
sudo docker compose -f "$CRAWL4AI_COMPOSE_FILE" --env-file "$ENV_FILE" up -d || { echo "Failed to start Crawl4AI stack"; exit 1; }

# Start Watchtower stack
sudo docker compose -f "$WATCHTOWER_COMPOSE_FILE" up -d || { echo "Failed to start Watchtower stack"; exit 1; }

# Start Netdata stack
echo "Starting Netdata stack..."
sudo docker compose -f "$NETDATA_COMPOSE_FILE" --env-file "$ENV_FILE" up -d || { echo "Failed to start Netdata stack"; exit 1; }

# If Adminer is not in a separate compose file, ensure it is up via n8n-docker-compose.yaml
if ! sudo docker ps | grep -q "adminer"; then
  echo "Adminer is not running. Attempting to start Adminer from n8n-docker-compose.yaml..."
  sudo docker compose -f "$N8N_COMPOSE_FILE" --env-file "$ENV_FILE" up -d adminer || echo "Warning: Could not start Adminer. Please check configuration."
fi


# Wait a few seconds for services to initialize
echo "Waiting for services to initialize..."
sleep 15

# Check status
echo "Checking status of Docker containers..."
sudo docker compose -f "$N8N_COMPOSE_FILE" --env-file "$ENV_FILE" ps
sudo docker compose -f "$FLOWISE_COMPOSE_FILE" --env-file "$ENV_FILE" ps
sudo docker compose -f "$QDRANT_COMPOSE_FILE" --env-file "$ENV_FILE" ps
sudo docker compose -f "$CRAWL4AI_COMPOSE_FILE" --env-file "$ENV_FILE" ps
sudo docker compose -f "$WATCHTOWER_COMPOSE_FILE" ps
sudo docker compose -f "$NETDATA_COMPOSE_FILE" --env-file "$ENV_FILE" ps

# Basic check if Caddy is running (port 80/443 should be listened by Docker proxy)
if ! sudo ss -tulnp | grep -q 'docker-proxy.*:80' || ! sudo ss -tulnp | grep -q 'docker-proxy.*:443'; then
    echo "ERROR: Caddy reverse proxy does not seem to be listening on ports 80 or 443." >&2
else
    echo "Caddy appears to be running."
fi

# Check that all containers are running
echo "Checking running containers..."
sleep 5

if ! sudo docker ps | grep -q "n8n"; then
  echo "ERROR: Container n8n is not running"
  exit 1
fi

if ! sudo docker ps | grep -q "caddy"; then
  echo "ERROR: Container caddy is not running"
  exit 1
fi

if ! sudo docker ps | grep -q "flowise"; then
  echo "ERROR: Container flowise is not running"
  exit 1
fi

if ! sudo docker ps | grep -q "qdrant"; then
  echo "ERROR: Container qdrant is not running"
  exit 1
fi

if ! sudo docker ps | grep -q "adminer"; then
  echo "ERROR: Container adminer is not running" >&2
  # Decide if this is critical enough to exit
  # exit 1
fi

if ! sudo docker ps | grep -q "crawl4ai"; then
  echo "ERROR: Container crawl4ai is not running" >&2
  # Decide if this is critical enough to exit
  # exit 1
fi

if ! sudo docker ps | grep -q "watchtower"; then
  echo "ERROR: Container watchtower is not running" >&2
  # Decide if this is critical enough to exit
  # exit 1
fi

if ! sudo docker ps | grep -q "netdata"; then
  echo "ERROR: Container netdata is not running" >&2
  # Decide if this is critical enough to exit
  # exit 1
fi

echo "✅ Services n8n, Flowise, Qdrant, Adminer, Crawl4AI, Watchtower, Netdata, Caddy successfully started"
echo "Services started. Check the output above for status."
echo "It might take a few minutes for all services to become fully available."
exit 0