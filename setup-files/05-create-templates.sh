#!/bin/bash

# Get variables from the main script via arguments
DOMAIN_NAME=$1
USER_EMAIL=$2

if [ -z "$DOMAIN_NAME" ] || [ -z "$USER_EMAIL" ]; then
  echo "ERROR: Domain name or user email not specified" >&2
  echo "Usage: $0 <domain_name> <user_email>" >&2
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

# Check for required templates
REQUIRED_TEMPLATES=(
    "n8n-docker-compose.yaml.template"
    "flowise-docker-compose.yaml.template"
    "qdrant-docker-compose.yaml.template"
    "crawl4ai-docker-compose.yaml.template"
    "watchtower-docker-compose.yaml.template"
    "netdata-docker-compose.yaml.template"
    "Caddyfile.template"
)

for TPL in "${REQUIRED_TEMPLATES[@]}"; do
    if [ ! -f "$TPL" ]; then
        echo "ERROR: Required template file '$TPL' not found in setup-files/ directory." >&2
        echo "Please ensure all necessary template files are present." >&2
        exit 1
    fi
done
echo "All required template files found."

# Copy templates to working files
# === Генерация всех docker-compose.yaml из .template через envsubst ===
echo "Генерируем docker-compose .yaml файлы из всех .template..."
for tmpl in *.template; do
  # Пропускаем Caddyfile.template, если не нужен .yaml
  if [[ "$tmpl" == "Caddyfile.template" ]]; then
    continue
  fi
  yaml="${tmpl%.template}.yaml"
  echo "→ Генерируем $yaml из $tmpl ..."
  envsubst < "$tmpl" > "$yaml"
  if [ $? -ne 0 ]; then
    echo "ОШИБКА: Не удалось сгенерировать $yaml из $tmpl через envsubst!"
    exit 1
  fi
  echo "✔ $yaml успешно создан."
done

echo "Копируем docker-compose.yaml файлы в /opt/ ..."
sudo mkdir -p /opt/
for yaml in *.yaml; do
  # Пропускаем не compose-файлы
  if [[ "$yaml" == "Caddyfile.yaml" ]]; then
    continue
  fi
  sudo cp "$yaml" "/opt/$yaml"
  if [ $? -ne 0 ]; then
    echo "ОШИБКА: Не удалось скопировать $yaml в /opt/"
    exit 1
  fi
  echo "✔ $yaml скопирован в /opt/"
done


# Check if copy operations were successful
FILES_TO_CHECK=(
    "/opt/n8n-docker-compose.yaml"
    "/opt/flowise-docker-compose.yaml"
    "/opt/qdrant-docker-compose.yaml"
    "/opt/crawl4ai-docker-compose.yaml"
    "/opt/watchtower-docker-compose.yaml"
    "/opt/netdata-docker-compose.yaml"
    "/opt/Caddyfile"
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

# Process Caddyfile template
echo "Processing Caddyfile template..."
if sudo sed -e "s/{DOMAIN_NAME}/$DOMAIN_NAME/g" -e "s/{USER_EMAIL}/$USER_EMAIL/g" Caddyfile.template > /opt/Caddyfile; then
  echo "Caddyfile created in /opt/Caddyfile"
  # Set ownership and permissions
  sudo chown root:root /opt/Caddyfile 2>/dev/null || echo "Warning: could not set ownership for /opt/Caddyfile"
  sudo chmod 644 /opt/Caddyfile 2>/dev/null || echo "Warning: could not set permissions for /opt/Caddyfile"
else
  echo "ERROR: Failed to process Caddyfile.template" >&2
  exit 1
fi

echo "Copying working configuration files to /opt/..."

# Copy YAML files
TARGET_DIR="/opt"
for yaml_file in n8n-docker-compose.yaml flowise-docker-compose.yaml qdrant-docker-compose.yaml crawl4ai-docker-compose.yaml watchtower-docker-compose.yaml netdata-docker-compose.yaml; do
  if [ -f "$yaml_file" ]; then
    sudo cp "$yaml_file" "$TARGET_DIR/$yaml_file" || { echo "ERROR: Failed to copy $yaml_file to $TARGET_DIR"; exit 1; }
    # Optional: Set permissions if needed (e.g., read-only for root)
    sudo chown root:root "$TARGET_DIR/$yaml_file" 2>/dev/null || true
    sudo chmod 644 "$TARGET_DIR/$yaml_file" 2>/dev/null || true
  else
    echo "ERROR: Working file $yaml_file not found for copying to $TARGET_DIR." >&2
    exit 1
  fi
done

# Copy Caddyfile
CADDY_TARGET_DIR="/opt/n8n" # Caddyfile goes into a subdirectory for n8n volume mount
sudo mkdir -p "$CADDY_TARGET_DIR" || { echo "ERROR: Failed to create $CADDY_TARGET_DIR"; exit 1; }
if [ -f "Caddyfile" ]; then
  sudo cp "Caddyfile" "$CADDY_TARGET_DIR/Caddyfile" || { echo "ERROR: Failed to copy Caddyfile to $CADDY_TARGET_DIR"; exit 1; }
  # Optional: Set permissions
  sudo chown root:root "$CADDY_TARGET_DIR/Caddyfile" 2>/dev/null || true
  sudo chmod 644 "$CADDY_TARGET_DIR/Caddyfile" 2>/dev/null || true
else
  echo "ERROR: Working Caddyfile not found for copying to $CADDY_TARGET_DIR." >&2
  exit 1
fi

echo "✅ Configuration files successfully copied to /opt/"

echo "✅ Templates and configuration files successfully created and copied"
exit 0