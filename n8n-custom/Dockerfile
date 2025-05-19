FROM n8nio/n8n:latest

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    build-essential \
    python3 \
    libjpeg-dev \
    libpng-dev \
    libgif-dev \
    librsvg2-dev \
    libtiff-dev \
    libwebp-dev \
    ffmpeg \
    graphicsmagick \
    imagemagick \
    tesseract-ocr \
    tesseract-ocr-rus \
    tesseract-ocr-eng \
    libreoffice \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Установка глобальных зависимостей
RUN npm install -g \
    # Базовые библиотеки
    axios \
    lodash \
    moment \
    @qdrant/js-client-rest \
    openai \
    langchain \
    # Обработка изображений и мультимедиа
    sharp \
    @ffmpeg/ffmpeg \
    gm \
    image-size \
    heic-convert \
    tesseract.js \
    # Работа с документами
    pdf-lib \
    pdf-parse \
    xlsx \
    exceljs \
    mammoth \
    @shelf/aws-lambda-libreoffice \
    html-pdf \
    # Работа с архивами и файлами
    jszip \
    archiver \
    unzipper \
    # Работа с данными и HTTP
    node-fetch \
    form-data \
    csv-parse \
    cheerio

# Настройка переменных окружения
ENV NODE_PATH=/usr/local/lib/node_modules

# Создание директории для кастомных модулей
RUN mkdir -p /home/node/.n8n/custom_modules

# Копирование кастомных хелперов
COPY ./helpers /home/node/.n8n/custom_modules/

# Настройка прав доступа
RUN chown -R node:node /home/node/.n8n/custom_modules
