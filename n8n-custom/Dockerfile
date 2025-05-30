FROM n8nio/n8n:latest

USER root

# Установка системных зависимостей для Alpine Linux
RUN apk add --no-cache \
    build-base \
    python3 \
    jpeg-dev \
    libpng-dev \
    giflib-dev \
    librsvg-dev \
    tiff-dev \
    libwebp-dev \
    ffmpeg \
    graphicsmagick \
    imagemagick \
    tesseract-ocr \
    tesseract-ocr-data-rus \
    tesseract-ocr-data-eng \
    libreoffice
# Примечание: если пакеты tesseract-ocr-data-rus/eng недоступны, языки можно скачать вручную или через ENV TESSDATA_PREFIX

# Установка глобальных npm-зависимостей (от root)
RUN npm install -g \
    axios \
    lodash \
    moment \
    @qdrant/js-client-rest \
    openai \
    langchain \
    sharp \
    @ffmpeg/ffmpeg \
    gm \
    image-size \
    heic-convert \
    tesseract.js \
    pdf-lib \
    pdf-parse \
    xlsx \
    exceljs \
    mammoth \
    @shelf/aws-lambda-libreoffice \
    html-pdf \
    jszip \
    archiver \
    unzipper \
    node-fetch \
    form-data \
    csv-parse \
    cheerio

USER node

# Настройка переменных окружения
ENV NODE_PATH=/usr/local/lib/node_modules

# Создание директории для кастомных модулей
RUN mkdir -p /home/node/.n8n/custom_modules

# Копирование кастомных хелперов с правильными правами
COPY --chown=node:node ./helpers /home/node/.n8n/custom_modules/
