#!/bin/bash

echo "=================================================================="
echo "🚀 Запуск всех сервисов (n8n, Flowise, Qdrant, Adminer, и др.)"
echo "=================================================================="

# Копирование кастомных модулей n8n в /opt/n8n-custom
SRC_N8N_CUSTOM="$(dirname "$0")/../n8n-custom"
DST_N8N_CUSTOM="/opt/n8n-custom"
echo "🔄 Проверка наличия кастомных модулей n8n..."
if [ -d "$SRC_N8N_CUSTOM" ]; then
    if [ -d "$DST_N8N_CUSTOM" ]; then
        echo "🗑️  Старый /opt/n8n-custom найден, удаляем..."
        sudo rm -rf "$DST_N8N_CUSTOM"
    fi
    echo "📁 Копируем кастомные модули n8n в /opt/n8n-custom..."
    sudo cp -a "$SRC_N8N_CUSTOM" "$DST_N8N_CUSTOM"
    sudo chown -R root:root "$DST_N8N_CUSTOM"
    echo "✅ Кастомные модули n8n скопированы."
else
    echo "⚠️  ВНИМАНИЕ: Директория n8n-custom не найдена по пути $SRC_N8N_CUSTOM. n8n может не стартовать!"
fi


# Загружаем функции проверки места на диске
if [ -f "$(dirname "$0")/check_disk_space.sh" ]; then
    source "$(dirname "$0")/check_disk_space.sh"
else
    # Определяем функции проверки места на диске прямо в скрипте, если файл не найден
    check_disk_space() {
        local required_space=$1 # в MB
        local mount_point=${2:-"/"}
        
        # Получаем свободное место в KB
        local free_space=$(df -k "$mount_point" | awk 'NR==2 {print $4}')
        # Переводим в MB для удобства сравнения
        local free_space_mb=$((free_space / 1024))
        
        if [ $free_space_mb -lt $required_space ]; then
            echo "❌ Недостаточно свободного места на диске $mount_point" >&2
            echo "Требуется: $required_space MB, Доступно: $free_space_mb MB" >&2
            return 1
        else
            echo "✅ Достаточно свободного места на диске $mount_point: $free_space_mb MB"
            return 0
        fi
    }

    clean_docker_space() {
        echo "⚙️ Очистка неиспользуемых Docker ресурсов..."
        
        # Очистка неиспользуемых контейнеров
        echo "→ Удаление остановленных контейнеров..."
        sudo docker container prune -f
        
        # Очистка неиспользуемых образов
        echo "→ Удаление неиспользуемых образов..."
        sudo docker image prune -f
        
        # Очистка неиспользуемых томов
        echo "→ Удаление неиспользуемых томов..."
        sudo docker volume prune -f
        
        echo "✅ Очистка завершена. Текущее использование диска Docker:"
        sudo docker system df
    }
fi 

# Функция для проверки существования Docker-образа
check_docker_image() {
    local image=$1
    echo "📋 Проверка доступности образа: $image"
    if ! sudo docker pull $image &>/dev/null; then
        echo "❌ ОШИБКА: Образ Docker '$image' не найден или недоступен" >&2
        return 1
    else
        echo "✅ Образ '$image' успешно загружен"
        return 0
    fi
}

# Функция для просмотра логов контейнера
show_container_logs() {
    local container=$1
    local lines=${2:-10}
    echo -e "\n📝 Последние логи контейнера $container:"
    sudo docker logs $container --tail $lines 2>/dev/null || echo "Логи недоступны"
}

# Функция диагностики
diagnostic_info() {
    echo -e "\n==== 🔍 ДИАГНОСТИЧЕСКАЯ ИНФОРМАЦИЯ ====" 
    echo -e "\n1. Список запущенных контейнеров:"
    sudo docker ps
    
    echo -e "\n2. Список всех контейнеров (включая остановленные):"
    sudo docker ps -a
    
    echo -e "\n3. Сетевые интерфейсы Docker:"
    sudo docker network ls
    
    echo -e "\n4. Том qdrant_storage:"
    sudo docker volume inspect qdrant_storage 2>/dev/null || echo "Том qdrant_storage не найден"
    
    echo -e "\n5. Переменные окружения в .env файле:"
    grep -E "QDRANT_API_KEY|CRAWL4AI_JWT_SECRET" $ENV_FILE 2>/dev/null || echo "Переменные не найдены в $ENV_FILE"
    
    echo -e "\n6. Проверка доступности образов Docker:"
    check_docker_image "n8nio/n8n:latest"
    check_docker_image "flowiseai/flowise:latest"
    check_docker_image "qdrant/qdrant:latest"
    check_docker_image "node:18-alpine" # для crawl4ai
    check_docker_image "containrrr/watchtower:latest"
}

# Функция проверки и исправления Caddyfile
check_and_fix_caddyfile() {
    local caddyfile="/opt/Caddyfile"
    echo -e "\n🔍 Проверка Caddyfile на наличие ошибок..."
    
    if [ ! -f "$caddyfile" ]; then
        echo "❌ ОШИБКА: Caddyfile не найден в $caddyfile" >&2
        return 1
    fi
    
    # Проверка на пустой email или неправильный формат переменной
    if grep -q "email\s*$" "$caddyfile" || grep -q "email\s*{" "$caddyfile" || grep -q "email\s*\${USER_EMAIL:-" "$caddyfile"; then
        echo "❌ ОШИБКА: Обнаружена проблема с директивой 'email' в Caddyfile" >&2
        echo "Содержимое проблемной строки:" >&2
        grep -n "email" "$caddyfile" >&2
        
        echo "⚙️ Попытка исправления Caddyfile..."
        
        # Создание резервной копии
        sudo cp "$caddyfile" "${caddyfile}.backup"
        
        # Исправление директивы email
        if grep -q "USER_EMAIL" "/opt/.env" 2>/dev/null; then
            USER_EMAIL=$(grep "USER_EMAIL" "/opt/.env" | cut -d'=' -f2)
            echo "✅ Найден email в .env файле: $USER_EMAIL"
            sudo sed -i "s/email\s*$/email $USER_EMAIL/" "$caddyfile"
            sudo sed -i "s/email\s*{/email $USER_EMAIL {/" "$caddyfile"
            sudo sed -i "s/email\s*\${USER_EMAIL:-[^}]*}/email $USER_EMAIL/" "$caddyfile"
        else
            echo "❌ Не удалось найти USER_EMAIL в .env файле" >&2
            echo "Введите email для использования в Caddyfile:"
            read -p "Email: " USER_EMAIL
            if [ -z "$USER_EMAIL" ]; then
                echo "❌ Не указан email. Используем значение по умолчанию admin@example.com" >&2
                USER_EMAIL="admin@example.com"
            fi
            sudo sed -i "s/email\s*$/email $USER_EMAIL/" "$caddyfile"
            sudo sed -i "s/email\s*{/email $USER_EMAIL {/" "$caddyfile"
            sudo sed -i "s/email\s*\${USER_EMAIL:-[^}]*}/email $USER_EMAIL/" "$caddyfile"
        fi
        
        echo "✅ Caddyfile исправлен. Создана резервная копия в ${caddyfile}.backup"
    else
        echo "✅ Директива 'email' в Caddyfile корректна"
    fi
    
    # Проверка синтаксиса Caddyfile
    echo "Проверка синтаксиса Caddyfile..."
    if ! sudo docker run --rm -v "$caddyfile:/etc/caddy/Caddyfile:ro" caddy:2 caddy validate --config /etc/caddy/Caddyfile &>/dev/null; then
        echo "❌ ОШИБКА: Caddyfile содержит синтаксические ошибки:" >&2
        sudo docker run --rm -v "$caddyfile:/etc/caddy/Caddyfile:ro" caddy:2 caddy validate --config /etc/caddy/Caddyfile
        echo "Пожалуйста, исправьте синтаксические ошибки в $caddyfile вручную" >&2
        return 1
    else
        echo "✅ Синтаксис Caddyfile корректен"
        return 0
    fi
}

# Проверка Docker
if ! sudo docker info > /dev/null 2>&1; then
    echo "❌ КРИТИЧЕСКАЯ ОШИБКА: Docker не запущен" >&2
    exit 1
fi

# Define compose file paths
N8N_COMPOSE_FILE="/opt/n8n-docker-compose.yaml"
FLOWISE_COMPOSE_FILE="/opt/flowise-docker-compose.yaml"
QDRANT_COMPOSE_FILE="/opt/qdrant-docker-compose.yaml"
CRAWL4AI_COMPOSE_FILE="/opt/crawl4ai-docker-compose.yaml"
WATCHTOWER_COMPOSE_FILE="/opt/watchtower-docker-compose.yaml"
NETDATA_COMPOSE_FILE="/opt/netdata-docker-compose.yaml"
WAHA_COMPOSE_FILE="/opt/waha-docker-compose.yaml"
MEM0_COMPOSE_FILE="/opt/mem0-docker-compose.yaml"
ENV_FILE="/opt/.env" # Assuming .env is copied to /opt

# Check if compose files exist
if [ ! -f "$N8N_COMPOSE_FILE" ]; then
    echo "Error: $N8N_COMPOSE_FILE not found." >&2
    exit 1
fi
if [ ! -f "$FLOWISE_COMPOSE_FILE" ]; then
    echo "Error: $FLOWISE_COMPOSE_FILE not found." >&2
    exit 1
fi
if [ ! -f "$QDRANT_COMPOSE_FILE" ]; then
    echo "Error: $QDRANT_COMPOSE_FILE not found." >&2
    exit 1
fi
if [ ! -f "$CRAWL4AI_COMPOSE_FILE" ]; then
    echo "Error: $CRAWL4AI_COMPOSE_FILE not found." >&2
    exit 1
fi
if [ ! -f "$WATCHTOWER_COMPOSE_FILE" ]; then
    echo "Error: $WATCHTOWER_COMPOSE_FILE not found." >&2
    exit 1
fi
if [ ! -f "$NETDATA_COMPOSE_FILE" ]; then
    echo "Error: $NETDATA_COMPOSE_FILE not found." >&2
    exit 1
fi
if [ ! -f "$WAHA_COMPOSE_FILE" ]; then
    echo "Error: $WAHA_COMPOSE_FILE not found." >&2
    exit 1
fi
if [ ! -f "$MEM0_COMPOSE_FILE" ]; then
    echo "Error: $MEM0_COMPOSE_FILE not found." >&2
    exit 1
fi
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: $ENV_FILE not found." >&2
    exit 1
fi

echo "========================================================="
echo "  ⚙️ Старт всех сервисов: n8n, Flowise, Qdrant, Adminer, Crawl4AI, Watchtower, Netdata, Caddy, PostgreSQL, Redis"
echo "=========================================================" 

# Функция запуска сервиса с повторными попытками
start_service() {
  local compose_file=$1
  local service_name=$2
  local env_file=$3
  local max_retries=2
  local retry_count=0

  echo -e "\n======================"
  echo "⚡ Запуск $service_name..."
  echo -e "======================\n"
  
  # Проверка валидности Docker Compose файла
  check_compose_file "$compose_file"
  if [ $? -ne 0 ]; then
    echo -e "\n❌ Критическая ошибка: $compose_file содержит ошибки, проверьте синтаксис YAML."
    return 1
  fi
  
  # Команда для запуска сервиса
  local start_cmd="sudo docker compose -f $compose_file"
  if [ -n "$env_file" ]; then
    start_cmd="$start_cmd --env-file $env_file"
  fi
  start_cmd="$start_cmd up -d"
  
  # Пробуем запустить с повторными попытками
  while [ $retry_count -lt $max_retries ]; do
    echo "Запуск $service_name (попытка $((retry_count+1))/$max_retries)..."
    eval $start_cmd
    
    if [ $? -eq 0 ]; then
      local verify_cmd="sudo docker ps | grep -q \"$service_name\""
      sleep 3  # Короткая пауза для того, чтобы контейнер успел стартовать
      # Проверяем запуск
      if eval $verify_cmd; then
        echo "✅ $service_name успешно запущен"
        return 0
      else
        echo "⚠️ $service_name не появился в списке контейнеров"
      fi
    fi

    retry_count=$((retry_count+1))
    if [ $retry_count -lt $max_retries ]; then
      echo "⚠️ Сбой при запуске $service_name, повторная попытка через 5 секунд..."
      sleep 5
    else
      echo "❌ Не удалось запустить $service_name после $max_retries попыток!"
      return 1
    fi
  done
}

# Функция для проверки валидности Docker Compose файла
check_compose_file() {
  local compose_file=$1
  echo "Проверка валидности $compose_file..."
  if sudo docker compose -f "$compose_file" config > /dev/null 2>&1; then
    echo "✅ $compose_file валиден"
    return 0
  else
    echo "❌ ОШИБКА: $compose_file содержит ошибки"
    return 1
  fi
}

# Функция для проверки и создания сети Docker
ensure_docker_network() {
  local network_name=$1
  if ! sudo docker network inspect "$network_name" &> /dev/null; then
    echo -e "\n❗ Сеть $network_name не существует, создаем..."
    sudo docker network create "$network_name"
    if [ $? -eq 0 ]; then
      echo "✅ Сеть $network_name успешно создана"
      return 0
    else
      echo "❌ Ошибка при создании сети $network_name"
      return 1
    fi
  else
    echo "✅ Сеть $network_name уже существует"
    return 0
  fi
}

# Статистика запуска
successful_services=0
failed_services=0
total_services=9  # n8n, flowise, qdrant, crawl4ai, watchtower, netdata, adminer, waha, mem0

# Проверка и создание сети app-network для всех сервисов
ensure_docker_network "app-network"

# Проверка и исправление Caddyfile перед запуском сервисов
echo -e "\n⚙️ Проверка конфигурации Caddy перед запуском..."
check_and_fix_caddyfile
if [ $? -ne 0 ]; then
  echo "⚠️ Обнаружены проблемы в конфигурации Caddy. Попытка продолжить установку, но сервис Caddy может работать некорректно." >&2
  read -p "Продолжить установку несмотря на ошибки? (y/n): " CONTINUE
  if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
    echo "Установка прервана пользователем." >&2
    exit 1
  fi
fi

# Запуск n8n стека (включает Caddy, Postgres, Redis, Adminer)
start_service "$N8N_COMPOSE_FILE" "n8n" "$ENV_FILE"
if [ $? -eq 0 ]; then
  ((successful_services++))
  # Проверка сети Docker
  echo "\nПроверка сети Docker..."
  sleep 5
  if ! sudo docker network inspect app-network &> /dev/null; then
    echo "❌ Ошибка: Сеть app-network не создана"
    exit 1
  else
    echo "✅ Сеть app-network успешно создана"
    
    # Инициализация библиотек для n8n
    echo "\n======================"
    echo "⚙️ Инициализация библиотек для n8n..."
    echo "=======================\n"
    
    if [ -f "$(dirname "$0")/n8n-init-libraries.sh" ]; then
      "$(dirname "$0")/n8n-init-libraries.sh"
    else
      echo "⚠️ Скрипт инициализации библиотек не найден"
    fi
  fi
else
  ((failed_services++))
  echo "❌ Критическая ошибка: Не удалось запустить n8n стек"
  exit 1
fi

# Запуск Flowise стека
start_service "$FLOWISE_COMPOSE_FILE" "flowise" "$ENV_FILE"
if [ $? -eq 0 ]; then
  ((successful_services++))
else
  ((failed_services++))
  echo "❌ Критическая ошибка: Не удалось запустить Flowise стек"
  exit 1
fi



# Запуск оставшихся сервисов с отслеживанием статуса

# Запуск Qdrant
start_service "$QDRANT_COMPOSE_FILE" "qdrant" "$ENV_FILE"
if [ $? -eq 0 ]; then
  ((successful_services++))
else
  ((failed_services++))
  echo "❌ Критическая ошибка: Не удалось запустить Qdrant стек"
  exit 1
fi

# Запуск Crawl4AI
start_service "$CRAWL4AI_COMPOSE_FILE" "crawl4ai" "$ENV_FILE"
if [ $? -eq 0 ]; then
  ((successful_services++))
else
  ((failed_services++))
  echo "❌ Критическая ошибка: Не удалось запустить Crawl4AI стек"
  exit 1
fi

# Запуск Watchtower
start_service "$WATCHTOWER_COMPOSE_FILE" "watchtower" ""
if [ $? -eq 0 ]; then
  ((successful_services++))
else
  ((failed_services++))
  echo "❌ Критическая ошибка: Не удалось запустить Watchtower стек"
  exit 1
fi

# Запуск Netdata (опциональный компонент)
echo -e "\n======================\n⚙️ Запуск Netdata...\n======================\n"

# Флаг для пропуска установки Netdata
SKIP_NETDATA_INSTALL=false

# Проверка свободного места перед установкой Netdata
echo "Проверка свободного места перед установкой Netdata..."
# Netdata требует минимум 500MB свободного места
if ! check_disk_space 500; then
  echo "⚠️ Недостаточно свободного места для установки Netdata" >&2
  echo "Попытка очистки дискового пространства..." >&2
  clean_docker_space
  
  # Проверяем еще раз после очистки
  if ! check_disk_space 500; then
    echo "⚠️ Даже после очистки недостаточно места для Netdata" >&2
    read -p "Установка Netdata не рекомендуется. Пропустить установку Netdata? (y/n): " SKIP_NETDATA
    if [[ "$SKIP_NETDATA" =~ ^[Yy]$ ]]; then
      echo "ℹ️ Установка Netdata пропущена по решению пользователя"
      ((total_services--))
      SKIP_NETDATA_INSTALL=true
    fi
  fi
fi

# Продолжаем с установкой Netdata, если не пропускаем
if [ "$SKIP_NETDATA_INSTALL" = false ]; then
  start_service "$NETDATA_COMPOSE_FILE" "netdata" "$ENV_FILE"
  if [ $? -eq 0 ]; then
    ((successful_services++))
  else
    ((failed_services++))
    echo "⚠️ Не удалось запустить Netdata стек. Netdata не является критически важным компонентом, продолжаем установку..." >&2
    ((total_services--))
  fi
else
  echo "ℹ️ Установка Netdata пропущена"
fi

# Запуск Adminer (или проверка, если уже существует в n8n-docker-compose)
echo "\n======================="
echo "⚡ Проверка/запуск Adminer..."
echo "=======================\n"

if ! sudo docker ps | grep -q "adminer"; then
  echo "Adminer не запущен. Пробуем запустить его из n8n-docker-compose.yaml..."
  sudo docker compose -f "$N8N_COMPOSE_FILE" --env-file "$ENV_FILE" up -d adminer
  sleep 3
  if sudo docker ps | grep -q "adminer"; then
    echo "✅ Adminer успешно запущен"
    ((successful_services++))
  else
    echo "⚠️ Предупреждение: Adminer не удалось запустить, но это не критично"
    ((failed_services++))
  fi
else
  echo "✅ Adminer уже запущен"
  ((successful_services++))
fi

# Запуск WordPress
echo "\n======================="
echo "⚡ Запуск WordPress..."
echo "=======================\n"

WP_COMPOSE_FILE="/opt/wordpress-docker-compose.yaml"
if [ -f "$WP_COMPOSE_FILE" ]; then
  start_service "$WP_COMPOSE_FILE" "wordpress" "$ENV_FILE"
  if [ $? -eq 0 ]; then
    ((successful_services++))
    ((total_services++))
  else
    ((failed_services++))
    ((total_services++))
    echo "⚠️ Не удалось запустить WordPress стек, но продолжаем установку..." >&2
  fi
else
  echo "⚠️ Файл $WP_COMPOSE_FILE не найден. Пропускаем запуск WordPress." >&2
fi

# Запуск Waha
echo "\n=======================" 
echo "⚡ Запуск Waha..."
echo "=======================\n"

if [ -f "$WAHA_COMPOSE_FILE" ]; then
  start_service "$WAHA_COMPOSE_FILE" "waha" "$ENV_FILE"
  if [ $? -eq 0 ]; then
    ((successful_services++))
    # Увеличиваем счетчик total_services, если успешно запустили дополнительный сервис
    ((total_services++))
  else
    ((failed_services++))
    # Увеличиваем счетчик total_services даже при неудаче, так как мы пытались запустить сервис
    ((total_services++))
    echo "⚠️ Не удалось запустить сервис Waha, но продолжаем установку..." >&2
  fi
else
  echo "⚠️ Файл $WAHA_COMPOSE_FILE не найден. Пропускаем запуск Waha." >&2
  ((failed_services++))
fi

# Запуск Mem0
echo "\n=======================" 
echo "⚡ Запуск Mem0..."
echo "=======================\n"

if [ -f "$MEM0_COMPOSE_FILE" ]; then
  start_service "$MEM0_COMPOSE_FILE" "mem0" "$ENV_FILE"
  if [ $? -eq 0 ]; then
    ((successful_services++))
    # Увеличиваем счетчик total_services, если успешно запустили дополнительный сервис
    ((total_services++))
  else
    ((failed_services++))
    # Увеличиваем счетчик total_services даже при неудаче, так как мы пытались запустить сервис
    ((total_services++))
    echo "⚠️ Не удалось запустить сервис Mem0, но продолжаем установку..." >&2
  fi
else
  echo "⚠️ Файл $MEM0_COMPOSE_FILE не найден. Пропускаем запуск Mem0." >&2
  ((failed_services++))
fi

# Ждем инициализацию всех сервисов
echo "\n\n===========================================" 
echo "🕒 Ожидание инициализации всех сервисов..."
echo "==========================================\n"
sleep 8

# Итоговая проверка статуса
echo "\n\n=========================================="
echo "🔍 ФИНАЛЬНАЯ ПРОВЕРКА ВСЕХ СЕРВИСОВ"
echo "==========================================\n"

# Функция для проверки статуса сервиса
check_service() {
  local service=$1
  if sudo docker ps | grep -q "$service"; then
    echo "✅ $service - ЗАПУЩЕН"
    return 0
  else
    echo "❌ $service - НЕ ЗАПУЩЕН"
    return 1
  fi
}

# Проверяем все критические сервисы
check_service "n8n"
check_service "caddy"
check_service "flowise"
check_service "qdrant"
check_service "crawl4ai" 
check_service "watchtower"
check_service "netdata"
check_service "adminer" # Не критично, но проверяем
check_service "waha" # WhatsApp HTTP API

# Проверка WordPress и связанных сервисов
if sudo docker ps | grep -q "wordpress"; then
  check_service "wordpress"
  check_service "wordpress_db"
  # Увеличим счетчик сервисов, если они не были учтены ранее
  ((total_services++))
  ((total_services++))
  
  # Считаем WordPress только если он успешно запущен
  if sudo docker ps | grep -q "wordpress"; then
    ((successful_services++))
  else
    ((failed_services++))
  fi
  
  # Считаем базу данных WordPress только если она успешно запущена
  if sudo docker ps | grep -q "wordpress_db"; then
    ((successful_services++))
  else
    ((failed_services++))
  fi
fi

# Проверка, что Caddy слушает нужные порты
echo "\n- Проверка портов Caddy:"
if ! sudo ss -tulnp | grep -q 'docker-proxy.*:80' || ! sudo ss -tulnp | grep -q 'docker-proxy.*:443'; then
    echo "⚠️ Внимание: Caddy (обратный прокси) не слушает порты 80 или 443"
else
    echo "✅ Caddy слушает порты 80 и 443"
fi

# Выводим итоговую статистику
echo "\n========================================================="
echo "🏁 РЕЗУЛЬТАТЫ ЗАПУСКА:"
echo "   ✓ Успешно запущено: $successful_services из $total_services сервисов"
echo "   ✗ Не запущено: $failed_services сервисов"
if [ $failed_services -eq 0 ]; then
  echo "\n✅ ВСЕ СЕРВИСЫ УСПЕШНО ЗАПУЩЕНЫ!"
  echo "========================================================="
  echo "Сервисы успешно запущены! Скоро они станут доступны через веб-интерфейс."
else
  echo "\n⚠️ ВНИМАНИЕ: Не все сервисы запущены успешно."
  echo "========================================================="
  echo "Некоторые сервисы не запустились. Проверьте логи и конфигурацию."
fi

exit 0