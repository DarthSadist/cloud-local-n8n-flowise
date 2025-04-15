#!/bin/bash

# Скрипт для диагностики и восстановления системы
echo "================================================================="
echo "🔍 ДИАГНОСТИКА И ВОССТАНОВЛЕНИЕ СИСТЕМЫ"
echo "================================================================="

# Проверка запущен ли Docker
if ! sudo docker info &>/dev/null; then
    echo "❌ Docker не запущен. Запускаем Docker..."
    sudo systemctl start docker
    sleep 3
    if ! sudo docker info &>/dev/null; then
        echo "❌ Не удалось запустить Docker. Выход."
        exit 1
    fi
    echo "✅ Docker успешно запущен"
else
    echo "✅ Docker уже запущен"
fi

# Проверка и создание сети Docker
if ! sudo docker network inspect app-network &>/dev/null; then
    echo "🔄 Создаем сеть app-network..."
    sudo docker network create app-network
    echo "✅ Сеть app-network создана"
else
    echo "✅ Сеть app-network уже существует"
fi

# Проверка наличия всех томов Docker
VOLUMES=("n8n_data" "n8n_postgres_data" "n8n_redis_data" "flowise_data" "qdrant_storage" "caddy_data" "caddy_config")
for volume in "${VOLUMES[@]}"; do
    if ! sudo docker volume inspect "$volume" &>/dev/null; then
        echo "🔄 Создаем том $volume..."
        sudo docker volume create "$volume"
        echo "✅ Том $volume создан"
    else
        echo "✅ Том $volume уже существует"
    fi
done

# Проверка наличия .env файла в /opt/
if [ ! -f "/opt/.env" ]; then
    echo "❌ Файл .env не найден в /opt/. Копируем из текущей директории..."
    if [ -f ".env" ]; then
        sudo cp ".env" "/opt/.env"
        sudo chmod 600 "/opt/.env"
        echo "✅ Файл .env скопирован в /opt/"
    else
        echo "❌ Файл .env не найден ни в текущей директории, ни в /opt/. Создаем базовый .env..."
        sudo bash -c 'cat > /opt/.env << EOF
# Settings for n8n
N8N_ENCRYPTION_KEY=$(openssl rand -hex 20)
N8N_USER_MANAGEMENT_JWT_SECRET=$(openssl rand -hex 20)
N8N_DEFAULT_USER_EMAIL=nedox32@gmail.com
N8N_DEFAULT_USER_PASSWORD=admin123
SUBDOMAIN=n8n
GENERIC_TIMEZONE=UTC
FLOWISE_USERNAME=admin
FLOWISE_PASSWORD=admin123
POSTGRES_DB=n8n
POSTGRES_USER=n8n
POSTGRES_PASSWORD=postgres123
DOMAIN_NAME=flowdarth.ru
QDRANT_API_KEY=$(openssl rand -hex 16)
CRAWL4AI_JWT_SECRET=$(openssl rand -hex 16)
EOF'
        echo "✅ Создан базовый .env файл в /opt/"
    fi
fi

# Проверка и генерация docker-compose файлов из шаблонов
echo -e "\n🔄 Проверяем и генерируем docker-compose файлы из шаблонов..."
for tmpl in *.template; do
    if [[ "$tmpl" == "Caddyfile.template" ]]; then
        continue  # Пропускаем Caddyfile
    fi
    
    yaml="${tmpl%.template}.yaml"
    echo "→ Генерируем $yaml из $tmpl..."
    envsubst < "$tmpl" > "$yaml"
    if [ $? -ne 0 ]; then
        echo "❌ Ошибка при генерации $yaml из $tmpl"
        exit 1
    fi
    
    # Копирование в /opt/
    sudo cp "$yaml" "/opt/$yaml"
    if [ $? -ne 0 ]; then
        echo "❌ Ошибка при копировании $yaml в /opt/"
        exit 1
    fi
    echo "✅ $yaml сгенерирован и скопирован в /opt/"
done

# Проверяем наличие всех файлов в /opt/
echo -e "\n🔍 Проверяем наличие всех docker-compose файлов в /opt/..."
FILES=(
    "n8n-docker-compose.yaml"
    "flowise-docker-compose.yaml"
    "qdrant-docker-compose.yaml"
    "crawl4ai-docker-compose.yaml"
    "watchtower-docker-compose.yaml"
    "netdata-docker-compose.yaml"
)

for file in "${FILES[@]}"; do
    if [ ! -f "/opt/$file" ]; then
        echo "❌ Файл /opt/$file не найден!"
    else
        echo "✅ Файл /opt/$file существует"
    fi
done

# Запуск контейнеров
echo -e "\n🚀 Запускаем все контейнеры..."

# Запуск n8n (с Postgres, Redis, Caddy)
echo "🔄 Запускаем n8n, Postgres, Redis, Caddy..."
sudo docker compose -f /opt/n8n-docker-compose.yaml --env-file /opt/.env up -d
if [ $? -ne 0 ]; then
    echo "❌ Ошибка при запуске n8n"
else
    echo "✅ n8n успешно запущен"
fi

# Проверяем создание сети
sleep 5
if ! sudo docker network inspect app-network &>/dev/null; then
    echo "❌ Сеть app-network не создана. Создаем..."
    sudo docker network create app-network
    echo "✅ Сеть app-network создана"
fi

# Запуск Flowise
echo "🔄 Запускаем Flowise..."
sudo docker compose -f /opt/flowise-docker-compose.yaml --env-file /opt/.env up -d
if [ $? -ne 0 ]; then
    echo "❌ Ошибка при запуске Flowise"
else
    echo "✅ Flowise успешно запущен"
fi

# Запуск Qdrant
echo "🔄 Запускаем Qdrant..."
sudo docker compose -f /opt/qdrant-docker-compose.yaml --env-file /opt/.env up -d
if [ $? -ne 0 ]; then
    echo "❌ Ошибка при запуске Qdrant"
else
    echo "✅ Qdrant успешно запущен"
fi

# Запуск Crawl4AI
echo "🔄 Запускаем Crawl4AI..."
sudo docker compose -f /opt/crawl4ai-docker-compose.yaml --env-file /opt/.env up -d
if [ $? -ne 0 ]; then
    echo "❌ Ошибка при запуске Crawl4AI"
else
    echo "✅ Crawl4AI успешно запущен"
fi

# Запуск Watchtower
echo "🔄 Запускаем Watchtower..."
sudo docker compose -f /opt/watchtower-docker-compose.yaml up -d
if [ $? -ne 0 ]; then
    echo "❌ Ошибка при запуске Watchtower"
else
    echo "✅ Watchtower успешно запущен"
fi

# Запуск Netdata
echo "🔄 Запускаем Netdata..."
sudo docker compose -f /opt/netdata-docker-compose.yaml --env-file /opt/.env up -d
if [ $? -ne 0 ]; then
    echo "❌ Ошибка при запуске Netdata"
else
    echo "✅ Netdata успешно запущен"
fi

# Проверяем что Adminer запущен (обычно идет в составе n8n)
if ! sudo docker ps | grep -q "adminer"; then
    echo "🔄 Adminer не запущен. Запускаем из n8n-docker-compose.yaml..."
    sudo docker compose -f /opt/n8n-docker-compose.yaml --env-file /opt/.env up -d adminer
    if [ $? -ne 0 ]; then
        echo "⚠️ Adminer не удалось запустить, но это не критично"
    else
        echo "✅ Adminer успешно запущен"
    fi
else
    echo "✅ Adminer уже запущен"
fi

# Итоговая проверка
echo -e "\n🔍 Проверка запущенных контейнеров..."
sudo docker ps

echo -e "\n================================================================="
echo "✅ ДИАГНОСТИКА И ВОССТАНОВЛЕНИЕ ЗАВЕРШЕНЫ"
echo "================================================================="
echo "Проверьте, что все нужные сервисы запущены."
echo "Если что-то не запустилось, проверьте логи контейнеров командой:"
echo "sudo docker logs <имя_контейнера>"
echo -e "\n"
