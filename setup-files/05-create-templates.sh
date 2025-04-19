#!/bin/bash

# Get variables from the main script via arguments
DOMAIN_NAME=$1
USER_EMAIL=$2

if [ -z "$DOMAIN_NAME" ] || [ -z "$USER_EMAIL" ]; then
  echo "ERROR: Domain name or user email not specified" >&2
  echo "Usage: $0 <domain_name> <user_email>" >&2
  exit 1
fi

# Проверка свободного места на диске
FREE_SPACE=$(df -k / | awk 'NR==2 {print $4}')
MIN_SPACE=5242880  # 5GB в KB
if [ $FREE_SPACE -lt $MIN_SPACE ]; then
  echo "❌ ПРЕДУПРЕЖДЕНИЕ: Недостаточно свободного места на диске. Рекомендуется минимум 5GB." >&2
  echo "Текущее свободное место: $(df -h / | awk 'NR==2 {print $4}')" >&2
  read -p "Продолжить установку несмотря на недостаток места? (y/n): " CONTINUE
  if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
    echo "Установка прервана пользователем." >&2
    exit 1
  fi
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
  # Автоматическая проверка YAML для n8n-docker-compose.yaml
  if [[ "$output_path" == "/opt/n8n-docker-compose.yaml" ]]; then
    if ! docker compose -f "$output_path" config > /dev/null 2>&1; then
      echo "ОШИБКА: $output_path содержит синтаксические ошибки YAML!" >&2
      echo "Проверьте шаблон и значения переменных. Установка прервана." >&2
      exit 1
    fi
  fi
done

# === Генерация Caddyfile из Caddyfile.template ===
echo "Генерируем Caddyfile из шаблона..."
CADDY_TEMPLATE="Caddyfile.template"
CADDY_OUTPUT="/opt/Caddyfile" # Correct output path

if [ ! -f "$CADDY_TEMPLATE" ]; then
  echo "ОШИБКА: $CADDY_TEMPLATE не найден!"
  exit 1
fi

# Проверка наличия переменных в шаблоне
if ! grep -q '\$USER_EMAIL' "$CADDY_TEMPLATE"; then
  echo "ПРЕДУПРЕЖДЕНИЕ: В шаблоне Caddyfile отсутствует переменная \$USER_EMAIL" >&2
fi

if ! grep -q '\$DOMAIN_NAME' "$CADDY_TEMPLATE"; then
  echo "ПРЕДУПРЕЖДЕНИЕ: В шаблоне Caddyfile отсутствует переменная \$DOMAIN_NAME" >&2
fi

# Проверка значений переменных
if [ -z "$USER_EMAIL" ]; then
  echo "ОШИБКА: Переменная USER_EMAIL пуста. Проверьте передачу параметров." >&2
  exit 1
fi

if [ -z "$DOMAIN_NAME" ]; then
  echo "ОШИБКА: Переменная DOMAIN_NAME пуста. Проверьте передачу параметров." >&2
  exit 1
fi

# Use sudo tee to write to /opt/
( set -o allexport; source .env; set +o allexport; envsubst < "$CADDY_TEMPLATE" | sudo tee "$CADDY_OUTPUT" > /dev/null )
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to process template '$CADDY_TEMPLATE' with envsubst. Check .env file and template syntax." >&2
  sudo rm -f "$CADDY_OUTPUT" # Удаляем частично созданный файл из /opt/
  exit 1
fi

# Проверка результата подстановки переменных
if grep -q "email\s*$" "$CADDY_OUTPUT" || grep -q "email\s*{" "$CADDY_OUTPUT"; then
  echo "ОШИБКА: Переменная USER_EMAIL не была подставлена в Caddyfile" >&2
  echo "Содержимое проблемной строки:" >&2
  grep -n "email" "$CADDY_OUTPUT" >&2
  exit 1
fi

# Проверка синтаксиса Caddyfile с использованием Docker
echo "Проверка синтаксиса Caddyfile..."
if command -v docker &> /dev/null; then
  if ! sudo docker run --rm -v "$CADDY_OUTPUT:/etc/caddy/Caddyfile:ro" caddy:2 caddy validate --config /etc/caddy/Caddyfile; then
    echo "ОШИБКА: Caddyfile содержит синтаксические ошибки. Проверьте файл $CADDY_OUTPUT" >&2
    echo "Содержимое Caddyfile:" >&2
    sudo cat "$CADDY_OUTPUT" >&2
    exit 1
  fi
  echo "✅ Синтаксис Caddyfile проверен и корректен"
else
  echo "ПРЕДУПРЕЖДЕНИЕ: Docker не доступен, пропускаем проверку синтаксиса Caddyfile" >&2
fi

echo "✔ $CADDY_OUTPUT успешно создан."

echo "✅ Templates and configuration files successfully created"

echo "✅ Templates and configuration files successfully created and copied"
exit 0