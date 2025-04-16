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

# Check for required templates in the project root directory
REQUIRED_TEMPLATES=(
    "./n8n-docker-compose.yaml.template"
    "./flowise-docker-compose.yaml.template"
    "./qdrant-docker-compose.yaml.template"
    "./crawl4ai-docker-compose.yaml.template"
    "./watchtower-docker-compose.yaml.template"
    "./netdata-docker-compose.yaml.template"
    "./Caddyfile.template"
)

for TPL in "${REQUIRED_TEMPLATES[@]}"; do
    if [ ! -f "$TPL" ]; then
        echo "ERROR: Required template file '$TPL' not found in project root directory." >&2
        echo "Please ensure all necessary template files are present." >&2
        exit 1
    fi
done
echo "All required template files found."

# Check for .env file in project root before substitution
if [ ! -f ".env" ]; then
    echo "ERROR: .env file not found in project root. Cannot proceed with template substitution." >&2
    echo "Please ensure Step 5 (generate secrets) completed successfully." >&2
    exit 1
fi
echo "Found .env file. Proceeding with substitutions..."

# Export all variables from .env file
set -a
source ".env"
set +a

# Copy templates to working files
# === Генерация всех docker-compose.yaml из .template через envsubst ===
echo "Генерируем docker-compose .yaml файлы из всех .template..."
for tmpl in *.template; do
  # Пропускаем если это не файл
  [ -f "$tmpl" ] || continue
  # Пропускаем Caddyfile.template, т.к. он обрабатывается отдельно
  if [[ "$tmpl" == "Caddyfile.template" ]]; then
    continue
  fi
  
  # Получаем имя файла без расширения .template
  filename="${tmpl%.template}"
  output_path="/opt/$filename" # Correct output path
  echo "→ Генерируем $output_path из $tmpl ..." # Log correct path
  # Use sudo tee to write to /opt/
  ( set -o allexport; source .env; set +o allexport; envsubst < "$tmpl" | sudo tee "$output_path" > /dev/null )
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to process template '$tmpl' with envsubst. Check .env file and template syntax." >&2
    sudo rm -f "$output_path" # Удаляем частично созданный файл из /opt/
    exit 1
  fi
  echo "✔ $output_path успешно создан."
done

# === Генерация Caddyfile из Caddyfile.template ===
echo "Генерируем Caddyfile из шаблона..."
CADDY_TEMPLATE="Caddyfile.template"
CADDY_OUTPUT="/opt/Caddyfile" # Correct output path

if [ ! -f "$CADDY_TEMPLATE" ]; then
  echo "ОШИБКА: $CADDY_TEMPLATE не найден!"
  exit 1
fi
# Use sudo tee to write to /opt/
( set -o allexport; source .env; set +o allexport; envsubst < "$CADDY_TEMPLATE" | sudo tee "$CADDY_OUTPUT" > /dev/null )
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to process template '$CADDY_TEMPLATE' with envsubst. Check .env file and template syntax." >&2
  sudo rm -f "$CADDY_OUTPUT" # Удаляем частично созданный файл из /opt/
  exit 1
fi
echo "✔ $CADDY_OUTPUT успешно создан."

echo "✅ Templates and configuration files successfully created"

echo "✅ Templates and configuration files successfully created and copied"
exit 0