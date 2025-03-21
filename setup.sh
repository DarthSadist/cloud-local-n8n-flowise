#!/bin/bash

# Функция для проверки успешного выполнения команды
check_success() {
  if [ $? -ne 0 ]; then
    echo "❌ Ошибка при выполнении $1"
    echo "Установка прервана. Пожалуйста, исправьте ошибки и попробуйте снова."
    exit 1
  fi
}

# Функция для отображения прогресса
show_progress() {
  echo ""
  echo "========================================================"
  echo "   $1"
  echo "========================================================"
  echo ""
}

# Главная функция установки
main() {
  show_progress "🚀 Начало установки n8n, Flowise и Caddy"
  
  # Проверяем права администратора
  if [ "$EUID" -ne 0 ]; then
    if ! sudo -n true 2>/dev/null; then
      echo "Для установки требуются права администратора"
      echo "Пожалуйста, введите пароль администратора, когда будет запрошено"
    fi
  fi
  
  # Запрос данных пользователя
  echo "Для установки необходимо указать имя домена и email адрес."
  
  # Запрос доменного имени
  read -p "Введите имя вашего домена (например, example.com): " DOMAIN_NAME
  while [[ -z "$DOMAIN_NAME" ]]; do
    echo "Имя домена не может быть пустым"
    read -p "Введите имя вашего домена (например, example.com): " DOMAIN_NAME
  done
  
  # Запрос email адреса
  read -p "Введите ваш email (будет использоваться для входа в n8n): " USER_EMAIL
  while [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
    echo "Введите корректный email адрес"
    read -p "Введите ваш email (будет использоваться для входа в n8n): " USER_EMAIL
  done
  
  # Создаем директорию setup-files, если она не существует
  if [ ! -d "setup-files" ]; then
    mkdir -p setup-files
    check_success "создание директории setup-files"
  fi
  
  # Устанавливаем права на выполнение для всех скриптов
  chmod +x setup-files/*.sh 2>/dev/null || true
  
  # Шаг 1: Обновление системы
  show_progress "Шаг 1/7: Обновление системы"
  ./setup-files/01-update-system.sh
  check_success "обновление системы"
  
  # Шаг 2: Установка Docker
  show_progress "Шаг 2/7: Установка Docker"
  ./setup-files/02-install-docker.sh
  check_success "установка Docker"
  
  # Шаг 3: Настройка директорий
  show_progress "Шаг 3/7: Настройка директорий"
  ./setup-files/03-setup-directories.sh
  check_success "настройка директорий"
  
  # Шаг 4: Генерация секретных ключей
  show_progress "Шаг 4/7: Генерация секретных ключей"
  ./setup-files/04-generate-secrets.sh "$USER_EMAIL" "$DOMAIN_NAME"
  check_success "генерация секретных ключей"
  
  # Шаг 5: Создание шаблонов
  show_progress "Шаг 5/7: Создание конфигурационных файлов"
  ./setup-files/05-create-templates.sh "$DOMAIN_NAME"
  check_success "создание конфигурационных файлов"
  
  # Шаг 6: Настройка брандмауэра
  show_progress "Шаг 6/7: Настройка брандмауэра"
  ./setup-files/06-setup-firewall.sh
  check_success "настройка брандмауэра"
  
  # Шаг 7: Запуск сервисов
  show_progress "Шаг 7/7: Запуск сервисов"
  ./setup-files/07-start-services.sh
  check_success "запуск сервисов"
  
  # Загрузка сгенерированных паролей
  if [ -f "./setup-files/passwords.txt" ]; then
    source ./setup-files/passwords.txt
  fi
  
  # Установка завершена успешно
  show_progress "✅ Установка успешно завершена!"
  
  echo "n8n доступен по адресу: https://n8n.${DOMAIN_NAME}"
  echo "Flowise доступен по адресу: https://flowise.${DOMAIN_NAME}"
  echo ""
  echo "Данные для входа в n8n:"
  echo "Email: ${USER_EMAIL}"
  echo "Пароль: ${N8N_PASSWORD:-<проверьте файл .env>}"
  echo ""
  echo "Данные для входа в Flowise:"
  echo "Логин: admin"
  echo "Пароль: ${FLOWISE_PASSWORD:-<проверьте файл .env>}"
  echo ""
  echo "Обратите внимание, что для работы с доменным именем необходимо настроить DNS-записи,"
  echo "указывающие на IP-адрес данного сервера."
  echo ""
  echo "Для редактирования конфигурации используйте файлы:"
  echo "- n8n-docker-compose.yaml (конфигурация n8n и Caddy)"
  echo "- flowise-docker-compose.yaml (конфигурация Flowise)"
  echo "- .env (переменные окружения для всех сервисов)"
  echo "- Caddyfile (настройки обратного прокси)"
  echo ""
  echo "Чтобы перезапустить сервисы, выполните команды:"
  echo "docker compose -f n8n-docker-compose.yaml restart"
  echo "docker compose -f flowise-docker-compose.yaml restart"
}

# Запуск основной функции
main 