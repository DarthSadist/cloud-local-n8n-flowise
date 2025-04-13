#!/bin/bash

# Get variables from the main script via arguments
DOMAIN_NAME=$1

if [ -z "$DOMAIN_NAME" ]; then
  echo "ERROR: Domain name not specified"
  echo "Usage: $0 example.com"
  exit 1
fi

echo "Creating templates and configuration files..."

# Check for template files and create them
if [ ! -f "n8n-docker-compose.yaml.template" ]; then
  echo "Creating template n8n-docker-compose.yaml.template..."
  cat > n8n-docker-compose.yaml.template << EOL
version: '3'

volumes:
  n8n_data:
    external: true
  caddy_data:
    external: true
  caddy_config:

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    environment:
      - N8N_ENCRYPTION_KEY=\${N8N_ENCRYPTION_KEY}
      - N8N_USER_MANAGEMENT_DISABLED=false
      - N8N_DIAGNOSTICS_ENABLED=false
      - N8N_PERSONALIZATION_ENABLED=false
      - N8N_USER_MANAGEMENT_JWT_SECRET=\${N8N_USER_MANAGEMENT_JWT_SECRET}
      - N8N_DEFAULT_USER_EMAIL=\${N8N_DEFAULT_USER_EMAIL}
      - N8N_DEFAULT_USER_PASSWORD=\${N8N_DEFAULT_USER_PASSWORD}
      - N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
    volumes:
      - n8n_data:/home/node/.n8n
      - /opt/n8n/files:/files
    networks:
      - app-network

  caddy:
    image: caddy:2
    container_name: caddy
    restart: unless-stopped
    ports:
      - 80:80
      - 443:443
    volumes:
      - /opt/n8n/Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - app-network

networks:
  app-network:
    name: app-network
    driver: bridge
EOL
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create file n8n-docker-compose.yaml.template"
    exit 1
  fi
else
  echo "Template n8n-docker-compose.yaml.template already exists"
fi

if [ ! -f "flowise-docker-compose.yaml.template" ]; then
  echo "Creating template flowise-docker-compose.yaml.template..."
  cat > flowise-docker-compose.yaml.template << EOL
version: '3'

services:
  flowise:
    image: flowiseai/flowise
    restart: unless-stopped
    container_name: flowise
    environment:
      - PORT=3001
      - FLOWISE_USERNAME=\${FLOWISE_USERNAME}
      - FLOWISE_PASSWORD=\${FLOWISE_PASSWORD}
    volumes:
      - /opt/flowise:/root/.flowise
    networks:
      - app-network

networks:
  app-network:
    external: true
EOL
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create file flowise-docker-compose.yaml.template"
    exit 1
  fi
else
  echo "Template flowise-docker-compose.yaml.template already exists"
fi

if [ ! -f "qdrant-docker-compose.yaml.template" ]; then
  echo "Creating template qdrant-docker-compose.yaml.template..."
  cat > qdrant-docker-compose.yaml.template << EOL
# Add qdrant-docker-compose.yaml.template content here
EOL
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create file qdrant-docker-compose.yaml.template"
    exit 1
  fi
else
  echo "Template qdrant-docker-compose.yaml.template already exists"
fi

if [ ! -f "crawl4ai-docker-compose.yaml.template" ]; then
  echo "Creating template crawl4ai-docker-compose.yaml.template..."
  cat > crawl4ai-docker-compose.yaml.template << EOL
# Add crawl4ai-docker-compose.yaml.template content here
EOL
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create file crawl4ai-docker-compose.yaml.template"
    exit 1
  fi
else
  echo "Template crawl4ai-docker-compose.yaml.template already exists"
fi

if [ ! -f "watchtower-docker-compose.yaml.template" ]; then
  echo "Creating template watchtower-docker-compose.yaml.template..."
  cat > watchtower-docker-compose.yaml.template << EOL
version: '3.8'

services:
  watchtower:
    image: containrrr/watchtower:latest
    container_name: watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    # Check every day at 4 AM
    command: --schedule "0 0 4 * * *" --cleanup
    restart: always
EOL
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create file watchtower-docker-compose.yaml.template"
    exit 1
  fi
else
  echo "Template watchtower-docker-compose.yaml.template already exists"
fi

# Create netdata template if it doesn't exist
if [ ! -f "netdata-docker-compose.yaml.template" ]; then
  echo "Creating template netdata-docker-compose.yaml.template..."
  # Basic template content, actual content is in the separate file
  cat > netdata-docker-compose.yaml.template << EOL
version: '3.8'
services:
  netdata:
    image: netdata/netdata:latest
    # Add other necessary configurations
EOL
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create file netdata-docker-compose.yaml.template"
    exit 1
  fi
else
  echo "Template netdata-docker-compose.yaml.template already exists"
fi

# Copy templates to working files
cp n8n-docker-compose.yaml.template n8n-docker-compose.yaml
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to copy n8n-docker-compose.yaml.template to working file"
  exit 1
fi

cp flowise-docker-compose.yaml.template flowise-docker-compose.yaml
cp qdrant-docker-compose.yaml.template qdrant-docker-compose.yaml
cp crawl4ai-docker-compose.yaml.template crawl4ai-docker-compose.yaml
cp watchtower-docker-compose.yaml.template watchtower-docker-compose.yaml
cp netdata-docker-compose.yaml.template netdata-docker-compose.yaml

echo "Copying configuration files to /opt/ ..."

# Create /opt/ directory if it doesn't exist
sudo mkdir -p /opt/

# Copy essential files to /opt/
sudo cp n8n-docker-compose.yaml "/opt/n8n-docker-compose.yaml"
sudo cp flowise-docker-compose.yaml "/opt/flowise-docker-compose.yaml"
sudo cp qdrant-docker-compose.yaml "/opt/qdrant-docker-compose.yaml"
sudo cp crawl4ai-docker-compose.yaml "/opt/crawl4ai-docker-compose.yaml"
sudo cp watchtower-docker-compose.yaml "/opt/watchtower-docker-compose.yaml"
sudo cp netdata-docker-compose.yaml "/opt/netdata-docker-compose.yaml"
sudo cp .env "/opt/.env"

# Check if copy operations were successful
FILES_TO_CHECK=(
    "/opt/n8n-docker-compose.yaml"
    "/opt/flowise-docker-compose.yaml"
    "/opt/qdrant-docker-compose.yaml"
    "/opt/crawl4ai-docker-compose.yaml"
    "/opt/watchtower-docker-compose.yaml"
    "/opt/netdata-docker-compose.yaml"
    "/opt/.env"
)

COPY_FAILED=0
for FILE_PATH in "${FILES_TO_CHECK[@]}"; do
    if [ ! -f "$FILE_PATH" ]; then
        echo "ERROR: Failed to copy or find $FILE_PATH in /opt/" >&2
        COPY_FAILED=1
    fi
done

if [ $COPY_FAILED -eq 1 ]; then
   exit 1
fi

# Copy Caddyfile to /opt/
sudo cp Caddyfile /opt/Caddyfile || {
  echo "ERROR: Failed to copy Caddyfile to /opt/" >&2; exit 1;
}

# Copy pgvector init script to /opt/
if [ -f "./pgvector-init.sql" ]; then # Assuming pgvector-init.sql is in the main project dir now
  sudo cp ./pgvector-init.sql /opt/pgvector-init.sql || {
    echo "ERROR: Failed to copy pgvector-init.sql to /opt/" >&2; exit 1;
  }
else
  echo "Warning: ./pgvector-init.sql not found. PostgreSQL will not initialize pgvector automatically." >&2
fi

# Create Caddyfile
echo "Creating Caddyfile..."
cat <<EOF | sudo tee /opt/Caddyfile > /dev/null || { echo "Failed to create Caddyfile"; exit 1; }
{
  n8n.${DOMAIN_NAME} {
    reverse_proxy n8n:5678
  }

  flowise.${DOMAIN_NAME} {
    reverse_proxy flowise:3001
  }

  adminer.${DOMAIN_NAME} {
    reverse_proxy adminer:8080
  }

  crawl4ai.${DOMAIN_NAME} {
    reverse_proxy crawl4ai:8000
  }

  netdata.${DOMAIN_NAME} {
    reverse_proxy netdata:19999
  }
}
EOF
echo "Created /opt/Caddyfile"

echo "✅ Templates and configuration files created and copied to /opt/"
exit 0