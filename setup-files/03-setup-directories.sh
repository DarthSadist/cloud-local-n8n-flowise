 {{ ... }}
   exit 1
 fi
 
+# Creating necessary base directory for Caddyfile
 echo "Creating directories..."
 sudo mkdir -p /opt/n8n
 if [ $? -ne 0 ]; then
   echo "ERROR: Failed to create directory /opt/n8n"
   exit 1
 fi
 
 # Setting permissions
 sudo chown n8n:n8n /opt/n8n
 if [ $? -ne 0 ]; then
   echo "ERROR: Failed to change owner of directory /opt/n8n"
   exit 1
 fi

 # Creating docker volumes
 echo "Creating Docker volumes..."
 sudo docker volume create n8n_data || { echo "Failed to create n8n_data volume"; exit 1; }
 sudo docker volume create caddy_data || { echo "Failed to create caddy_data volume"; exit 1; }
 sudo docker volume create postgres_data || { echo "Failed to create postgres_data volume"; exit 1; }
 sudo docker volume create redis_data || { echo "Failed to create redis_data volume"; exit 1; }
 sudo docker volume create n8n_user_files || { echo "Failed to create n8n_user_files volume"; exit 1; }
 sudo docker volume create flowise_data || { echo "Failed to create flowise_data volume"; exit 1; }
 sudo docker volume create qdrant_data || { echo "Failed to create qdrant_data volume"; exit 1; }

 echo "✅ Directories and users successfully configured"
 exit 0 #!/bin/bash

echo "Setting up directories and users..."

# Creating n8n user if it doesn't exist
if ! id "n8n" &>/dev/null; then
  echo "Creating n8n user..."
  sudo adduser --disabled-password --gecos "" n8n
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create n8n user"
    exit 1
  fi
  
  # Generate random password
  N8N_PASSWORD=$(openssl rand -base64 12)
  echo "n8n:$N8N_PASSWORD" | sudo chpasswd
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to set password for n8n user"
    exit 1
  fi
  
  echo "✅ Created n8n user"
  sudo usermod -aG docker n8n
  if [ $? -ne 0 ]; then
    echo "WARNING: Failed to add n8n user to docker group"
    # Not exiting as this is not a critical error
  fi
else
  echo "User n8n already exists"
  
  # If user exists but password needs to be reset
  read -p "Do you want to reset the password for n8n user? (y/n): " reset_password
  if [ "$reset_password" = "y" ]; then
    N8N_PASSWORD=$(openssl rand -base64 12)
    echo "n8n:$N8N_PASSWORD" | sudo chpasswd
    if [ $? -ne 0 ]; then
      echo "ERROR: Failed to reset password for n8n user"
    else
      echo "✅ Password for n8n user has been reset"
    fi
  fi
fi