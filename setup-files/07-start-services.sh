#!/bin/bash

echo "=================================================================="
echo "🚀 Запуск всех сервисов (n8n, Flowise, Qdrant, Adminer, и др.)"
echo "==================================================================" 

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
    echo "\n📝 Последние логи контейнера $container:"
    sudo docker logs $container --tail $lines 2>/dev/null || echo "Логи недоступны"
}

# Функция диагностики
diagnostic_info() {
    echo "\n==== 🔍 ДИАГНОСТИЧЕСКАЯ ИНФОРМАЦИЯ ===="
    echo "\n1. Список запущенных контейнеров:"
    sudo docker ps
    
    echo "\n2. Список всех контейнеров (включая остановленные):"
    sudo docker ps -a
    
    echo "\n3. Сетевые интерфейсы Docker:"
    sudo docker network ls
    
    echo "\n4. Том qdrant_storage:"
    sudo docker volume inspect qdrant_storage 2>/dev/null || echo "Том qdrant_storage не найден"
    
    echo "\n5. Переменные окружения в .env файле:"
    grep -E "QDRANT_API_KEY|CRAWL4AI_JWT_SECRET" $ENV_FILE 2>/dev/null || echo "Переменные не найдены в $ENV_FILE"
    
    echo "\n6. Проверка доступности образов Docker:"
    check_docker_image "n8nio/n8n:latest"
    check_docker_image "flowiseai/flowise:latest"
    check_docker_image "qdrant/qdrant:latest"
    check_docker_image "node:18-alpine" # для crawl4ai
    check_docker_image "containrrr/watchtower:latest"
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

  echo "\n======================"
  echo "⚡ Запуск $service_name..."
  echo "======================\n"
  
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

# Статистика запуска
successful_services=0
failed_services=0
total_services=7  # n8n, flowise, qdrant, crawl4ai, watchtower, netdata, adminer

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

# Запуск Netdata
start_service "$NETDATA_COMPOSE_FILE" "netdata" "$ENV_FILE"
if [ $? -eq 0 ]; then
  ((successful_services++))
else
  ((failed_services++))
  echo "❌ Критическая ошибка: Не удалось запустить Netdata стек"
  exit 1
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

# Ждем инициализацию всех сервисов
echo "\n\n=========================================="
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