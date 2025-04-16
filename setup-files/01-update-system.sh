#!/bin/bash

echo "Updating system..."
# Setting environment variables to prevent interactive prompts
export DEBIAN_FRONTEND=noninteractive

# Configuring debconf for automatic service restart
echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections
sudo bash -c "cat > /etc/apt/apt.conf.d/70debconf << EOF
Dpkg::Options {
   \"--force-confdef\";
   \"--force-confold\";
}
EOF"

# apt options for automatic confirmation and preventing prompts
APT_OPTIONS="-o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef -y"

sudo apt-get update
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to update package list"
  exit 1
fi

# Adding -qq option for quieter output and option for automatic service restart
sudo DEBIAN_FRONTEND=noninteractive apt-get -qq install -y gettext
sudo DEBIAN_FRONTEND=noninteractive apt-get -qq upgrade $APT_OPTIONS
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to upgrade packages"
  exit 1
fi

sudo apt-get autoremove $APT_OPTIONS
sudo apt-get clean

echo "✅ System successfully updated"
exit 0