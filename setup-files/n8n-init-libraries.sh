#!/bin/bash

# Скрипт для автоматической установки базовых библиотек в n8n при первом запуске

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Путь к файлу с метками установки
INSTALL_MARKER="/opt/n8n-libraries-installed"

# Проверка наличия контейнера n8n
if ! docker ps | grep -q "n8n"; then
    echo -e "${RED}❌ Контейнер n8n не запущен${NC}"
    echo -e "${YELLOW}Запустите n8n с помощью команды:${NC} sudo ./setup-files/07-start-services.sh"
    exit 1
fi

# Проверка наличия маркера установки
if [ -f "$INSTALL_MARKER" ]; then
    echo -e "${GREEN}✅ Библиотеки уже установлены${NC}"
    exit 0
fi

echo -e "${YELLOW}📦 Начинаем установку базовых библиотек для n8n...${NC}"

# Список базовых библиотек для установки
LIBRARIES=(
    # Базовые библиотеки
    "axios"
    "lodash"
    "moment"
    "@qdrant/js-client-rest"
    "openai"
    "langchain"
    
    # Обработка изображений и мультимедиа
    "sharp"
    "@ffmpeg/ffmpeg"
    "gm"
    "image-size"
    "heic-convert"
    "tesseract.js"
    
    # Работа с документами
    "pdf-lib"
    "pdf-parse"
    "xlsx"
    "exceljs"
    "mammoth"
    "@shelf/aws-lambda-libreoffice"
    "html-pdf"
    
    # Работа с архивами и файлами
    "jszip"
    "archiver"
    "unzipper"
    
    # Работа с данными и HTTP
    "node-fetch"
    "form-data"
    "csv-parse"
    "cheerio"
)

# Установка библиотек
FAILED=0
for LIB in "${LIBRARIES[@]}"; do
    echo -e "${YELLOW}📦 Установка $LIB...${NC}"
    docker exec n8n npm install -g $LIB
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Библиотека $LIB успешно установлена${NC}"
    else
        echo -e "${RED}❌ Ошибка при установке библиотеки $LIB${NC}"
        FAILED=$((FAILED + 1))
    fi
done

# Сохранение списка установленных пакетов
echo -e "${YELLOW}📋 Сохранение списка установленных пакетов...${NC}"
docker exec n8n npm list -g --depth=0 > /opt/n8n-packages.txt

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ Все библиотеки успешно установлены${NC}"
    # Создание маркера установки
    touch "$INSTALL_MARKER"
    echo "$(date) - Libraries installed successfully" > "$INSTALL_MARKER"
    exit 0
else
    echo -e "${RED}❌ Не удалось установить $FAILED библиотек${NC}"
    exit 1
fi
