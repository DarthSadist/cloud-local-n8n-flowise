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

# Проверка прав доступа к директории /opt/
if [ ! -w "/opt/" ]; then
    echo "⚠️ Внимание: недостаточно прав для записи в /opt/"
    # Попытка исправить права
    sudo chmod 755 /opt/
    if [ ! -w "/opt/" ]; then
        echo "❌ Не удалось установить права на запись в /opt/"
        exit 1
    else
        echo "✅ Права доступа к /opt/ успешно установлены"
    fi
fi

# Функция для проверки валидности YAML файлов
check_yaml_validity() {
    local yaml_file=$1
    if [ -f "$yaml_file" ]; then
        if sudo docker compose -f "$yaml_file" config > /dev/null 2>&1; then
            echo "✅ $yaml_file валиден"
            return 0
        else
            echo "❌ $yaml_file содержит ошибки синтаксиса YAML"
            return 1
        fi
    else
        echo "❌ $yaml_file не найден"
        return 1
    fi
}

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

# Очистим предыдущие файлы из /opt
echo "🗑️ Удаляем старые файлы..."
sudo rm -f /opt/*-docker-compose.yaml* 2>/dev/null

# Функция для проверки валидности YAML
validate_yaml() {
    local file=$1
    # Проверяем, что в первых 10 строках есть version
    if ! head -n 10 "$file" | grep -q "version:"; then
        echo "❌ Ошибка: В файле $file не найдена версия YAML. Добавляем..."
        # Добавляем версию в начало файла
        sed -i '1s/^/version: \'3.8\'\n\n/' "$file"
        return 1
    fi
    
    # Проверяем базовую структуру services
    if ! grep -q "services:" "$file"; then
        echo "❌ Ошибка: В файле $file не найден раздел services. Добавляем..."
        # Добавляем раздел services после версии
        sed -i '/version:/a\nservices:\n  # Сервисы будут добавлены автоматически' "$file"
        return 1
    fi
    
    return 0
}

for tmpl in *.template; do
    if [[ "$tmpl" == "Caddyfile.template" ]]; then
        continue  # Пропускаем Caddyfile
    fi
    
    # Получаем имя без .template
    filename="${tmpl%.template}"
    echo "→ Генерируем $filename из $tmpl..."
    
    # Генерируем файл через envsubst
    echo 'version: \'3.8\'' > "$filename"
    echo '' >> "$filename"
    echo 'services:' >> "$filename"
    envsubst < "$tmpl" | grep -v "^version:" | sed '/^services:/d' >> "$filename"
    
    if [ $? -ne 0 ]; then
        echo "❌ Ошибка при генерации $filename из $tmpl"
        exit 1
    fi
    
    # Проверяем и фиксим файл
    validate_yaml "$filename"
    
    # Копируем в /opt/
    sudo cp "$filename" "/opt/$filename"
    if [ $? -ne 0 ]; then
        echo "❌ Ошибка при копировании $filename в /opt/"
        exit 1
    fi
    echo "✅ $filename сгенерирован и скопирован в /opt/"
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
