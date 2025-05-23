#!/bin/bash

set -euo pipefail

echo "🔧 Начинаем настройку пользователей и директорий..."

# Проверка и создание пользователя n8n
if ! id "n8n" &>/dev/null; then
  echo "👤 Создаём пользователя n8n..."
  sudo adduser --disabled-password --gecos "" n8n
  
  # Генерация и установка случайного пароля
  N8N_PASSWORD=$(openssl rand -base64 16)
  echo "n8n:${N8N_PASSWORD}" | sudo chpasswd
  echo "🔑 Пользователь n8n создан, пароль: ${N8N_PASSWORD}"

  sudo usermod -aG docker n8n || echo "⚠️ Не удалось добавить n8n в группу docker"
else
  echo "✅ Пользователь n8n уже существует."
  read -rp "🔄 Сбросить пароль пользователю n8n? (y/n): " reset_pass
  if [[ "$reset_pass" == "y" ]]; then
    N8N_PASSWORD=$(openssl rand -base64 16)
    echo "n8n:${N8N_PASSWORD}" | sudo chpasswd
    echo "🔑 Пароль для n8n сброшен на: ${N8N_PASSWORD}"
  fi
fi

# Create /opt directory if it doesn't exist
if [ ! -d "/opt" ]; then
    echo "Creating /opt directory..."
    sudo mkdir -p /opt
    sudo chmod 755 /opt
fi

# Create /opt/flowise directory with proper permissions
echo "Creating /opt/flowise directory..."
sudo mkdir -p /opt/flowise
sudo chmod 777 /opt/flowise
echo "✅ Directory /opt/flowise created with proper permissions"

# Создание директории с правильными правами
echo "📂 Создаём директорию /opt/n8n..."
sudo mkdir -p /opt/n8n
sudo chown -R n8n:n8n /opt/n8n
echo "✅ Директория настроена."

# Создание Docker volume-ов через цикл -- УДАЛЕНО, теперь в 03-create-volumes.sh

echo "🎉 Директории и пользователи успешно настроены!"
exit 0
