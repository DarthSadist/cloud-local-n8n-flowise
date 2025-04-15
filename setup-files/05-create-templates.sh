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

# Проверка наличия .env файла перед подстановкой
if [ ! -f "../.env" ]; then
    echo "ERROR: .env file not found in project root. Cannot proceed with template substitution." >&2
    echo "Please ensure Step 5 (generate secrets) completed successfully." >&2
    exit 1
fi
echo "Found .env file. Proceeding with substitutions..."

# Copy templates to working files
# === Генерация всех docker-compose.yaml из .template через envsubst ===
echo "Генерируем docker-compose .yaml файлы из всех .template..."
for tmpl in *.template; do
  # Пропускаем Caddyfile.template, т.к. он обрабатывается отдельно
  if [[ "$tmpl" == "Caddyfile.template" ]]; then
    continue
  fi
  
  # Получаем имя файла без расширения .template
  filename="${tmpl%.template}"
  echo "→ Генерируем $filename из $tmpl ..."
  ( set -o allexport; source ../.env; set +o allexport; envsubst < "$tmpl" > "$filename" )
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to process template '$tmpl' with envsubst. Check .env file and template syntax." >&2
    rm -f "$filename" # Удаляем частично созданный файл
    exit 1
  fi
  echo "✔ $filename успешно создан."
done

# === Обработка Caddyfile ===
CADDY_TEMPLATE="Caddyfile.template"
CADDY_OUTPUT="Caddyfile"
echo "→ Генерируем $CADDY_OUTPUT из $CADDY_TEMPLATE ..."
if [ ! -f "$CADDY_TEMPLATE" ]; then
  echo "ОШИБКА: $CADDY_TEMPLATE не найден!"
  exit 1
fi
( set -o allexport; source ../.env; set +o allexport; envsubst < "$CADDY_TEMPLATE" > "$CADDY_OUTPUT" )
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to process template '$CADDY_TEMPLATE' with envsubst. Check .env file and template syntax." >&2
  rm -f "$CADDY_OUTPUT" # Удаляем частично созданный файл
  exit 1
fi
echo "✔ $CADDY_OUTPUT успешно создан."

echo "Копируем конфигурационные и docker-compose файлы в /opt/ ..."
sudo mkdir -p /opt/

# Копируем все docker-compose файлы и Caddyfile
FILES_TO_COPY=(
    "n8n-docker-compose.yaml"
    "flowise-docker-compose.yaml"
    "qdrant-docker-compose.yaml"
    "crawl4ai-docker-compose.yaml"
    "watchtower-docker-compose.yaml"
    "netdata-docker-compose.yaml"
    "Caddyfile" # Добавляем Caddyfile в список копирования
)

for file in "${FILES_TO_COPY[@]}"; do
  if [ -f "$file" ]; then
    sudo cp "$file" "/opt/$file"
    if [ $? -ne 0 ]; then
      echo "ERROR: Failed to copy $file to /opt/. Check permissions." >&2
      # Возможно, стоит прервать выполнение, если копирование критично
      # exit 1
    fi
    echo "✔ $file скопирован в /opt/"
  else
    echo "⚠️ ВНИМАНИЕ: Файл $file не найден для копирования"
  fi
done

# Проверка наличия скопированных файлов в /opt/
echo "Verifying copied files in /opt/..."
COPIED_FILES=(
    n8n-docker-compose.yaml
    flowise-docker-compose.yaml
    qdrant-docker-compose.yaml
    crawl4ai-docker-compose.yaml
    watchtower-docker-compose.yaml
    netdata-docker-compose.yaml
    Caddyfile
)

ALL_COPIED=true
for file in "${COPIED_FILES[@]}"; do
  if [ ! -f "/opt/$file" ]; then
    echo "ERROR: File /opt/$file was not found after copy attempt." >&2
    ALL_COPIED=false
  else
     echo "✅ File /opt/$file found in /opt/"
  fi
done

if [ "$ALL_COPIED" = false ]; then
    echo "ERROR: Not all required files were successfully copied to /opt/. Aborting." >&2
    exit 1
fi

echo "✅ All required files successfully copied to /opt/."

echo "✅ Templates and configuration files successfully created and copied"
exit 0