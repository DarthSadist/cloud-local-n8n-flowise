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

# Writing values to .env file
cat > .env << EOL
# Settings for n8n
N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY
N8N_USER_MANAGEMENT_JWT_SECRET=$N8N_USER_MANAGEMENT_JWT_SECRET
N8N_DEFAULT_USER_EMAIL=$USER_EMAIL
N8N_DEFAULT_USER_PASSWORD=$N8N_PASSWORD

# n8n host configuration
SUBDOMAIN=n8n
GENERIC_TIMEZONE=$GENERIC_TIMEZONE

# Settings for Flowise
FLOWISE_USERNAME=admin
FLOWISE_PASSWORD=$FLOWISE_PASSWORD

# Settings for PostgreSQL
POSTGRES_DB=$POSTGRES_DB
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

# Domain settings
DOMAIN_NAME=$DOMAIN_NAME

# --- Qdrant Settings (Optional) ---
# Uncomment the following line in this file AND in qdrant-docker-compose.yaml to enable API key
QDRANT_API_KEY=$QDRANT_API_KEY

# Secret for Crawl4AI API authentication
CRAWL4AI_JWT_SECRET=$CRAWL4AI_JWT_SECRET
EOL

if [ $? -ne 0 ]; then
  echo "ERROR: Failed to create .env file"
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