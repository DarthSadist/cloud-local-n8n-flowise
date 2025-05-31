 #!/bin/bash

# Get variables from the main script via arguments
USER_EMAIL=$1
DOMAIN_NAME=$2
GENERIC_TIMEZONE=$3

if [ -z "$USER_EMAIL" ] || [ -z "$DOMAIN_NAME" ]; then
  echo "ERROR: Email or domain name not specified"
  echo "Usage: $0 user@example.com example.com [timezone]"
  exit 1
fi

if [ -z "$GENERIC_TIMEZONE" ]; then
  GENERIC_TIMEZONE="UTC"
fi

echo "Generating secret keys and passwords..."

# Function to generate random strings
generate_random_string() {
  length=$1
  cat /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&*()-_=+' | fold -w ${length} | head -n 1
}

# Function to generate safe passwords (no special bash characters)
generate_safe_password() {
  length=$1
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${length} | head -n 1
}

# Generating keys and passwords
N8N_ENCRYPTION_KEY=$(generate_random_string 40)
if [ -z "$N8N_ENCRYPTION_KEY" ]; then
  echo "ERROR: Failed to generate encryption key for n8n"
  exit 1
fi

N8N_USER_MANAGEMENT_JWT_SECRET=$(generate_random_string 40)
if [ -z "$N8N_USER_MANAGEMENT_JWT_SECRET" ]; then
  echo "ERROR: Failed to generate JWT secret for n8n"
  exit 1
fi

# Use safer password generation function (alphanumeric only)
N8N_PASSWORD=$(generate_safe_password 16)
if [ -z "$N8N_PASSWORD" ]; then
  echo "ERROR: Failed to generate password for n8n"
  exit 1
fi

FLOWISE_PASSWORD=$(generate_safe_password 16)
if [ -z "$FLOWISE_PASSWORD" ]; then
  echo "ERROR: Failed to generate password for Flowise"
  exit 1
fi

# PostgreSQL Credentials
POSTGRES_DB="n8n" # Default database name
POSTGRES_USER="n8n" # Default username
POSTGRES_PASSWORD=$(generate_safe_password 16)
if [ -z "$POSTGRES_PASSWORD" ]; then
  echo "ERROR: Failed to generate password for PostgreSQL"
  exit 1
fi

# --- Generate Qdrant Credentials (Optional) ---
# Qdrant can run without an API key for internal network access.
# Generate one for optional security layer.
QDRANT_API_KEY=$(openssl rand -hex 32)

# Generate a random CRAWL4AI_JWT_SECRET
CRAWL4AI_JWT_SECRET=$(openssl rand -hex 32)

# Debug output for all variables
set +x
echo "[DEBUG] N8N_ENCRYPTION_KEY: $N8N_ENCRYPTION_KEY"
echo "[DEBUG] N8N_USER_MANAGEMENT_JWT_SECRET: $N8N_USER_MANAGEMENT_JWT_SECRET"
echo "[DEBUG] N8N_DEFAULT_USER_EMAIL: $USER_EMAIL"
echo "[DEBUG] N8N_DEFAULT_USER_PASSWORD: $N8N_PASSWORD"
echo "[DEBUG] GENERIC_TIMEZONE: $GENERIC_TIMEZONE"
echo "[DEBUG] FLOWISE_PASSWORD: $FLOWISE_PASSWORD"
echo "[DEBUG] POSTGRES_DB: $POSTGRES_DB"
echo "[DEBUG] POSTGRES_USER: $POSTGRES_USER"
echo "[DEBUG] POSTGRES_PASSWORD: $POSTGRES_PASSWORD"
echo "[DEBUG] DOMAIN_NAME: $DOMAIN_NAME"
echo "[DEBUG] QDRANT_API_KEY: $QDRANT_API_KEY"
echo "[DEBUG] CRAWL4AI_JWT_SECRET: $CRAWL4AI_JWT_SECRET"
set -x

# Abort if any required variable is empty
if [ -z "$N8N_ENCRYPTION_KEY" ] || [ -z "$N8N_USER_MANAGEMENT_JWT_SECRET" ] || [ -z "$USER_EMAIL" ] || [ -z "$N8N_PASSWORD" ] || [ -z "$FLOWISE_PASSWORD" ] || [ -z "$POSTGRES_DB" ] || [ -z "$POSTGRES_USER" ] || [ -z "$POSTGRES_PASSWORD" ] || [ -z "$DOMAIN_NAME" ] || [ -z "$QDRANT_API_KEY" ] || [ -z "$CRAWL4AI_JWT_SECRET" ]; then
  echo "[ERROR] One or more required variables are empty. Aborting .env generation." >&2
  exit 1
fi

# Escape all values for .env before heredoc
N8N_ENCRYPTION_KEY_ESCAPED=$(printf '%s' "$N8N_ENCRYPTION_KEY" | sed 's/"/\\"/g')
N8N_USER_MANAGEMENT_JWT_SECRET_ESCAPED=$(printf '%s' "$N8N_USER_MANAGEMENT_JWT_SECRET" | sed 's/"/\\"/g')
N8N_DEFAULT_USER_EMAIL_ESCAPED=$(printf '%s' "$USER_EMAIL" | sed 's/"/\\"/g')
N8N_PASSWORD_ESCAPED=$(printf '%s' "$N8N_PASSWORD" | sed 's/"/\\"/g')
GENERIC_TIMEZONE_ESCAPED=$(printf '%s' "$GENERIC_TIMEZONE" | sed 's/"/\\"/g')
FLOWISE_PASSWORD_ESCAPED=$(printf '%s' "$FLOWISE_PASSWORD" | sed 's/"/\\"/g')
POSTGRES_DB_ESCAPED=$(printf '%s' "$POSTGRES_DB" | sed 's/"/\\"/g')
POSTGRES_USER_ESCAPED=$(printf '%s' "$POSTGRES_USER" | sed 's/"/\\"/g')
POSTGRES_PASSWORD_ESCAPED=$(printf '%s' "$POSTGRES_PASSWORD" | sed 's/"/\\"/g')
DOMAIN_NAME_ESCAPED=$(printf '%s' "$DOMAIN_NAME" | sed 's/"/\\"/g')
QDRANT_API_KEY_ESCAPED=$(printf '%s' "$QDRANT_API_KEY" | sed 's/"/\\"/g')
CRAWL4AI_JWT_SECRET_ESCAPED=$(printf '%s' "$CRAWL4AI_JWT_SECRET" | sed 's/"/\\"/g')

cat > .env << EOL
# Settings for n8n
N8N_ENCRYPTION_KEY="$N8N_ENCRYPTION_KEY_ESCAPED"
N8N_USER_MANAGEMENT_JWT_SECRET="$N8N_USER_MANAGEMENT_JWT_SECRET_ESCAPED"
N8N_DEFAULT_USER_EMAIL="$N8N_DEFAULT_USER_EMAIL_ESCAPED"
N8N_DEFAULT_USER_PASSWORD="$N8N_PASSWORD_ESCAPED"

# n8n host configuration
SUBDOMAIN="n8n"
GENERIC_TIMEZONE="$GENERIC_TIMEZONE_ESCAPED"
N8N_BASIC_AUTH_USER="admin"
N8N_BASIC_AUTH_PASSWORD="$N8N_PASSWORD_ESCAPED"
N8N_PORT="5678"
N8N_PROTOCOL="https"
NODE_ENV="production"
EXECUTIONS_PROCESS="main"
QUEUE_BULL_REDIS_HOST="n8n_redis"
QUEUE_BULL_REDIS_PORT="6379"

# Settings for Flowise
FLOWISE_USERNAME="admin"
FLOWISE_PASSWORD="$FLOWISE_PASSWORD_ESCAPED"
FLOWISE_HOST="0.0.0.0"
FLOWISE_PORT="3001"
FLOWISE_DATABASE_TYPE="postgres"
FLOWISE_DATABASE_HOST="postgres"
FLOWISE_DATABASE_PORT="5432"
FLOWISE_DATABASE_NAME="$POSTGRES_DB_ESCAPED"
FLOWISE_DATABASE_USER="$POSTGRES_USER_ESCAPED"
FLOWISE_DATABASE_PASSWORD="$POSTGRES_PASSWORD_ESCAPED"
FLOWISE_QDRANT_HOST="qdrant"
FLOWISE_QDRANT_PORT="6333"
FLOWISE_LOG_LEVEL="info"
FLOWISE_DEBUG="false"

# Путь к кастомным модулям n8n
SRC_N8N_CUSTOM="${SRC_N8N_CUSTOM:-/home/den/cloud-local-n8n-flowise/n8n-custom}"
# Путь к директории назначения кастомных модулей n8n
DST_N8N_CUSTOM="${DST_N8N_CUSTOM:-/opt/n8n-custom}"

# Settings for PostgreSQL
POSTGRES_DB="$POSTGRES_DB_ESCAPED"
POSTGRES_USER="$POSTGRES_USER_ESCAPED"
POSTGRES_PASSWORD="$POSTGRES_PASSWORD_ESCAPED"

# Domain settings
DOMAIN_NAME="$DOMAIN_NAME_ESCAPED"

# --- Qdrant Settings ---
# API Key для аутентификации в Qdrant
QDRANT_API_KEY="$QDRANT_API_KEY_ESCAPED"
# Настройки сервиса Qdrant
QDRANT_ENABLE_DASHBOARD="true"
QDRANT_HTTP_PORT="6333"
QDRANT_GRPC_PORT="6334"
# Настройки производительности
QDRANT_MAX_SEARCH_THREADS="4"
QDRANT_TELEMETRY_DISABLED="true"
QDRANT_INDEXING_THRESHOLD="50000"
QDRANT_MEMMAP_THRESHOLD="20000"

# Secret for Crawl4AI API authentication
CRAWL4AI_JWT_SECRET="$CRAWL4AI_JWT_SECRET_ESCAPED"

# --- Waha WhatsApp HTTP API Settings ---
WAHA_WORKER_ID="waha"
WAHA_HOST="0.0.0.0"
WAHA_API_PORT="3000"
WAHA_START_SESSION="true"
WAHA_API_KEY="$(openssl rand -hex 16)"
WAHA_WEBHOOK_URL="https://n8n.${DOMAIN_NAME_ESCAPED}/webhook/waha"
WAHA_WEBHOOK_ALLOWED_EVENTS="message,message.any,message.ack"
WAHA_LOG_LEVEL="info"
WAHA_MAX_ATTACHMENT_SIZE="16"
WAHA_CHROME_HEADLESS="true"

# --- Mem0 Settings ---
MEM0_API_KEY="$(openssl rand -hex 16)"
OPENAI_API_KEY="sk-your-openai-api-key" # Замените на реальный ключ OpenAI API
MEM0_HOST="0.0.0.0"
MEM0_PORT="3456"

# Path to this .env file (used by startup scripts)
ENV_FILE="/opt/.env"
EOL

# Проверка успешности создания .env файла
if [ ! -f ".env" ]; then
  echo "ERROR: Failed to create .env file. Please check permissions and disk space in the project root directory." >&2
  exit 1
fi

echo "Secret keys generated and saved to .env file"

# Save passwords for future use - using quotes to properly handle special characters
echo "N8N_PASSWORD=\"$N8N_PASSWORD\"" > ./setup-files/passwords.txt
echo "FLOWISE_PASSWORD=\"$FLOWISE_PASSWORD\"" >> ./setup-files/passwords.txt
echo "POSTGRES_PASSWORD=\"$POSTGRES_PASSWORD\"" >> ./setup-files/passwords.txt
echo " " >> ./setup-files/passwords.txt
echo "Qdrant Vector DB is running internally." >> ./setup-files/passwords.txt
echo "  - Access from n8n/Flowise via: http://qdrant:6333" >> ./setup-files/passwords.txt
echo "  - Optional API Key (if enabled in .env & compose): $QDRANT_API_KEY" >> ./setup-files/passwords.txt
echo " " >> ./setup-files/passwords.txt
echo "Access URLs:" >> ./setup-files/passwords.txt
echo "  n8n:      https://n8n.${DOMAIN_NAME}" >> ./setup-files/passwords.txt
echo "  Flowise:  https://flowise.${DOMAIN_NAME}" >> ./setup-files/passwords.txt
echo "  Adminer:  https://adminer.${DOMAIN_NAME}" >> ./setup-files/passwords.txt
echo " " >> ./setup-files/passwords.txt
echo "Adminer Connection Details (for n8n DB):" >> ./setup-files/passwords.txt
echo "  System:   PostgreSQL" >> ./setup-files/passwords.txt
echo "  Server:   n8n_postgres (this is the Docker service name)" >> ./setup-files/passwords.txt
echo "  Username: ${POSTGRES_USER}" >> ./setup-files/passwords.txt
echo "  Password: ${POSTGRES_PASSWORD}" >> ./setup-files/passwords.txt
echo "  Database: ${POSTGRES_DB}" >> ./setup-files/passwords.txt
echo " " >> ./setup-files/passwords.txt
echo "Crawl4AI API JWT Secret:" >> ./setup-files/passwords.txt
echo "  - This secret is used for API authentication." >> ./setup-files/passwords.txt
echo "  - Stored in .env as CRAWL4AI_JWT_SECRET" >> ./setup-files/passwords.txt
echo "Qdrant API Key:" >> ./setup-files/passwords.txt
echo "  - This key is used for Qdrant API authentication." >> ./setup-files/passwords.txt
echo "  - Stored in .env as QDRANT_API_KEY" >> ./setup-files/passwords.txt
echo "=======================================================" >> ./setup-files/passwords.txt

echo "✅ Secret keys and passwords successfully generated"
exit 0