#!/bin/bash

# Function to check successful command execution
check_success() {
  if [ $? -ne 0 ]; then
    echo "❌ Error executing $1"
    echo "Installation aborted. Please fix the errors and try again."
    exit 1
  fi
}

# Function to display progress
show_progress() {
  echo ""
  echo "========================================================"
  echo "   $1"
  echo "========================================================"
  echo ""
}

# Main installation function
main() {
  clear
  echo "========================================================================="
  echo "            🚀 Starting Installation 🚀"
  echo " n8n, Flowise, Qdrant, Adminer, Crawl4AI, Watchtower, Netdata, Caddy, PostgreSQL, Redis "
  echo "========================================================================="
  echo
 
  # Check administrator rights
  if [ "$EUID" -ne 0 ]; then
    if ! sudo -n true 2>/dev/null; then
      echo "Administrator rights are required for installation"
      echo "Please enter the administrator password when prompted"
    fi
  fi
  
  # Request user data
  echo "For installation, you need to specify a domain name and email address."
  
  # Request domain name
  read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME
  while [[ -z "$DOMAIN_NAME" ]]; do
    echo "Domain name cannot be empty"
    read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME
  done
  
  # Request email address
  read -p "Enter your email (will be used for n8n login): " USER_EMAIL
  while [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
    echo "Enter a valid email address"
    read -p "Enter your email (will be used for n8n login): " USER_EMAIL
  done
  
  # Request timezone
  DEFAULT_TIMEZONE=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")
  read -p "Enter your timezone (default: $DEFAULT_TIMEZONE): " GENERIC_TIMEZONE
  GENERIC_TIMEZONE=${GENERIC_TIMEZONE:-$DEFAULT_TIMEZONE}
  
  # Create setup-files directory if it doesn't exist
  if [ ! -d "setup-files" ]; then
    mkdir -p setup-files
    check_success "creating setup-files directory"
  fi
  
  # Set execution permissions for all scripts
  chmod +x setup-files/*.sh 2>/dev/null || true
  
  # Step 1: System update
  show_progress "Step 1/8: System update"
  ./setup-files/01-update-system.sh
  check_success "system update"
  
  # Step 2: Docker installation
  show_progress "Step 2/8: Docker installation"
  ./setup-files/02-install-docker.sh
  check_success "Docker installation"
  
  # Step 3: Create Docker volumes
  show_progress "Step 3/8: Create Docker volumes"
  ./setup-files/03-create-volumes.sh
  check_success "create Docker volumes"
  
  # Step 4: Directory setup
  show_progress "Step 4/8: Directory and User Setup"
  if [ -f "./setup-files/03b-setup-directories.sh" ]; then
    ./setup-files/03b-setup-directories.sh
  elif [ -f "./setup-files/03-setup-directories.sh" ]; then
    echo "Warning: Found old script name 03-setup-directories.sh. Consider renaming to 03b-setup-directories.sh." >&2
    ./setup-files/03-setup-directories.sh
  else
    echo "Error: Directory setup script (03b-setup-directories.sh or 03-setup-directories.sh) not found." >&2
    exit 1
  fi
  check_success "directory setup"
  
  # Step 5: Secret key generation
  show_progress "Step 5/8: Secret key generation"
  ./setup-files/04-generate-secrets.sh "$USER_EMAIL" "$DOMAIN_NAME" "$GENERIC_TIMEZONE"
  check_success "secret key generation"
  
  # Step 5b: WordPress Configuration
  show_progress "Step 5b/8: WordPress Configuration"
  ./setup-files/04b-setup-wordpress.sh
  check_success "WordPress configuration"
  
  # Step 6: Template creation
  show_progress "Step 6/8: Configuration file creation"
  # Pass both DOMAIN_NAME and USER_EMAIL for Caddyfile processing
  ./setup-files/05-create-templates.sh "$DOMAIN_NAME" "$USER_EMAIL"
  check_success "configuration file creation"
  
  # Step 7: Firewall setup
  show_progress "Step 7/8: Firewall setup"
  ./setup-files/06-setup-firewall.sh
  check_success "firewall setup"
  
  # Copy .env file to /opt for service startup
  echo "Copying .env file to /opt/..."
  if [ -f ".env" ]; then 
    sudo cp ".env" "/opt/.env" || { echo "Failed to copy .env to /opt"; exit 1; } 
    sudo chown root:root "/opt/.env" || echo "Warning: Failed to set root ownership for /opt/.env"
    sudo chmod 600 "/opt/.env" || echo "Warning: Failed to set permissions for /opt/.env"
  else
    echo "Error: .env not found in project root. Cannot copy to /opt/.env." >&2 
    exit 1
  fi
  
  # Copy pgvector initialization script to /opt
  echo "Copying pgvector-init.sql to /opt/..."
  if [ -f "setup-files/pgvector-init.sql" ]; then
    sudo cp "setup-files/pgvector-init.sql" "/opt/pgvector-init.sql" || { echo "Failed to copy pgvector-init.sql to /opt"; exit 1; }
    # Optional: Set permissions if needed, although it's just a read-only script
    sudo chown root:root "/opt/pgvector-init.sql" 2>/dev/null || true
    sudo chmod 644 "/opt/pgvector-init.sql" 2>/dev/null || true
  else
    echo "Error: setup-files/pgvector-init.sql not found. This is required for Flowise/Postgres." >&2
    exit 1
  fi
  
  # Step 8: Service launch
  show_progress "Step 8/8: Service launch"
  ./setup-files/07-start-services.sh
  check_success "service launch"
  
  # Load generated passwords for final display
  PASSWORDS_FILE="./setup-files/passwords.txt"
  N8N_PASSWORD="<not found>"
  FLOWISE_PASSWORD="<not found>"
  if [ -f "$PASSWORDS_FILE" ]; then
      N8N_PASSWORD=$(grep '^N8N_PASSWORD=' "$PASSWORDS_FILE" | cut -d'=' -f2)
      FLOWISE_PASSWORD=$(grep '^FLOWISE_PASSWORD=' "$PASSWORDS_FILE" | cut -d'=' -f2)
      # Provide defaults if grep fails or value is empty
      N8N_PASSWORD=${N8N_PASSWORD:-<check /opt/.env>}
      FLOWISE_PASSWORD=${FLOWISE_PASSWORD:-<check /opt/.env>}
  else
      echo "Warning: passwords.txt not found. Cannot display passwords."
  fi
  
  # Installation successfully completed
  show_progress "✅ Installation successfully completed!"
  
  echo "======================================================="
  echo
  echo "All services should now be running."
  echo "Access n8n, Flowise, Adminer, Crawl4AI, and Netdata using the details above."
  echo "Qdrant is internal. Watchtower runs in the background."
  echo
  echo "Useful commands:"
  echo "  - n8n logs:       sudo docker logs n8n"
  echo "  - Flowise logs:   sudo docker logs flowise"
  echo "  - WordPress logs: sudo docker logs wordpress"
  echo "  - WP DB logs:     sudo docker logs wordpress_db"
  echo "  - Caddy logs:     sudo docker logs caddy"
  echo "  - Adminer logs:   sudo docker logs adminer"
  echo "  - Crawl4AI logs:  sudo docker logs crawl4ai"
  echo "  - Qdrant logs:    sudo docker logs qdrant"
  echo "  - Watchtower logs:sudo docker logs watchtower"
  echo "  - Postgres logs:  sudo docker logs n8n_postgres"
  echo "  - Redis logs:     sudo docker logs n8n_redis"
  echo "  - Netdata logs:   sudo docker logs netdata"
  echo "======================================================="
  echo
  echo "n8n is available at: https://n8n.${DOMAIN_NAME}"
  echo "Flowise is available at: https://flowise.${DOMAIN_NAME}"
  echo "WordPress is available at: https://wordpress.${DOMAIN_NAME}"
  echo "Adminer is available at: https://adminer.${DOMAIN_NAME}"
  echo "Crawl4AI is available at: https://crawl4ai.${DOMAIN_NAME}"
  echo "Netdata is available at: https://netdata.${DOMAIN_NAME}"
  echo ""
  echo "Login credentials for n8n:"
  echo "Email: ${USER_EMAIL}"
  echo "Password: ${N8N_PASSWORD}"
  echo ""
  echo "Login credentials for Flowise:"
  echo "Username: admin"
  echo "Password: ${FLOWISE_PASSWORD}"
  echo ""
  echo "Please note that for the domain name to work, you need to configure DNS records"
  echo "pointing to the IP address of this server."
  echo ""
  echo "======================================================="
  echo
  echo "Please save the credentials above securely!"
  echo "The Crawl4AI JWT Secret is needed for API access."
  echo "The temporary file setup-files/passwords.txt will be deleted now."
  
  # Removing temporary password file for security
  if [ -f "$PASSWORDS_FILE" ]; then
    rm "$PASSWORDS_FILE"
    echo "Temporary password file $PASSWORDS_FILE removed."
  fi
  
  echo ""
  echo "To edit the configuration, use the following files:"
  echo "- n8n-docker-compose.yaml (n8n, Caddy, PostgreSQL, Redis configuration)"
  echo "- flowise-docker-compose.yaml (Flowise configuration)"
  echo "- qdrant-docker-compose.yaml (Qdrant configuration)"
  echo "- crawl4ai-docker-compose.yaml (Crawl4AI configuration)"
  echo "- netdata-docker-compose.yaml (Netdata configuration)"
  echo "- watchtower-docker-compose.yaml (Watchtower configuration)"
  echo "- .env (environment variables for all services)"
  echo "- Caddyfile (reverse proxy settings)"
  echo ""
  echo "To restart services, execute the commands:"
  echo "docker compose -f n8n-docker-compose.yaml restart"
  echo "docker compose -f flowise-docker-compose.yaml restart"
}

# Run main function
main