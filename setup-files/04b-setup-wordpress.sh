#!/bin/bash

# Генерация паролей и секретов для WordPress
generate_wp_secrets() {
  echo "Генерация секретов для WordPress..."
  
  # Генерация паролей и ключей
  WP_DB_USER="wordpress_user"
  WP_DB_NAME="wordpress"
  WP_TABLE_PREFIX="wp_"
  
  # Генерация случайных паролей
  WP_DB_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 20)
  WP_DB_ROOT_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 20)
  
  # Сохранение паролей в файл паролей
  echo "WP_DB_USER=$WP_DB_USER" >> ./setup-files/passwords.txt
  echo "WP_DB_PASSWORD=$WP_DB_PASSWORD" >> ./setup-files/passwords.txt
  echo "WP_DB_ROOT_PASSWORD=$WP_DB_ROOT_PASSWORD" >> ./setup-files/passwords.txt
  echo "WP_DB_NAME=$WP_DB_NAME" >> ./setup-files/passwords.txt
  echo "WP_TABLE_PREFIX=$WP_TABLE_PREFIX" >> ./setup-files/passwords.txt
  
  # Добавление переменных окружения в .env файл
  echo "" >> .env
  echo "# WordPress Configuration" >> .env
  echo "WP_DB_USER=$WP_DB_USER" >> .env
  echo "WP_DB_PASSWORD=$WP_DB_PASSWORD" >> .env
  echo "WP_DB_ROOT_PASSWORD=$WP_DB_ROOT_PASSWORD" >> .env
  echo "WP_DB_NAME=$WP_DB_NAME" >> .env
  echo "WP_TABLE_PREFIX=$WP_TABLE_PREFIX" >> .env
  
  echo "✅ Секреты WordPress успешно сгенерированы."
}

# Выполнение функции генерации секретов
generate_wp_secrets
