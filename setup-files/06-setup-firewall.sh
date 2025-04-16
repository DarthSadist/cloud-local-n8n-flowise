#!/bin/bash

echo "Setting up firewall..."

# Check if ufw is installed
if command -v ufw &> /dev/null; then
  echo "UFW is already installed, opening required ports..."
  
  # Open ports
  sudo ufw allow 80
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to open port 80"
    exit 1
  fi
  
  sudo ufw allow 443
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to open port 443"
    exit 1
  fi
  
  # Check if ufw is active
  sudo ufw status | grep -q "Status: active"
  if [ $? -ne 0 ]; then
    echo "UFW is not active, activating..."
    # Allow necessary ports
    sudo ufw allow 80/tcp comment 'Allow HTTP'
    sudo ufw allow 443/tcp comment 'Allow HTTPS'

    # Allow SSH access BEFORE enabling firewall
    echo "Allowing SSH connections..."
    sudo ufw allow ssh comment 'Allow SSH access'

    # Enable firewall
    echo "Enabling firewall..."
    sudo ufw --force enable
    if [ $? -ne 0 ]; then
      echo "ERROR: Failed to activate UFW"
      exit 1
    fi
  fi
  
  echo "Ports 80 and 443 are open in the firewall"
else
  echo "UFW is not installed. Installing..."
  sudo apt-get install -y ufw
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install UFW"
    exit 1
  fi
  
  # Allow necessary ports
  sudo ufw allow 80/tcp comment 'Allow HTTP'
  sudo ufw allow 443/tcp comment 'Allow HTTPS'

  # Allow SSH access BEFORE enabling firewall
  echo "Allowing SSH connections..."
  sudo ufw allow ssh comment 'Allow SSH access'

  # Enable firewall
  echo "Enabling firewall..."
  sudo ufw --force enable
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to activate UFW"
    exit 1
  fi
  
  echo "Firewall installed and ports 80, 443 are open"
fi

echo "✅ Firewall successfully configured"
exit 0 