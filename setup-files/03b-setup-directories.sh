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

# Создание директории с правильными правами
echo "📂 Создаём директорию /opt/n8n..."
sudo mkdir -p /opt/n8n
sudo chown -R n8n:n8n /opt/n8n
echo "✅ Директория настроена."

# Создание Docker volume-ов через цикл
volumes=("n8n_data" "caddy_data" "postgres_data" "redis_data" "n8n_user_files" "flowise_data" "qdrant_data")

for volume in "${volumes[@]}"; do
  echo "🐳 Создаём Docker volume: ${volume}..."
  sudo docker volume create "${volume}" >/dev/null || { echo "❌ Ошибка создания Docker volume: ${volume}"; exit 1; }
done

echo "🎉 Все директории, пользователи и Docker volume успешно настроены!"
exit 0
