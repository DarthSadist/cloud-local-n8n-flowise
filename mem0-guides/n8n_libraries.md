# Руководство по использованию сторонних JavaScript библиотек в n8n

## Содержание

1. [Введение](#введение)
2. [Установка и настройка](#установка-и-настройка)
3. [Управление библиотеками](#управление-библиотеками)
4. [Использование библиотек в узле Code](#использование-библиотек-в-узле-code)
5. [Встроенные хелперы](#встроенные-хелперы)
6. [Примеры использования](#примеры-использования)
7. [Часто задаваемые вопросы](#часто-задаваемые-вопросы)

## Введение

n8n — это мощный инструмент автоматизации рабочих процессов, который позволяет создавать сложные интеграции между различными сервисами. Одной из ключевых возможностей n8n является узел Code, который позволяет выполнять произвольный JavaScript код. Однако стандартная конфигурация n8n имеет ограниченный набор доступных библиотек.

Это руководство описывает, как расширить возможности n8n для работы со сторонними JavaScript библиотеками, такими как:

#### Базовые библиотеки

- `axios` - для HTTP-запросов
- `lodash` - для манипуляций с данными
- `moment` - для работы с датами и временем
- `@qdrant/js-client-rest` - для взаимодействия с Qdrant
- `openai` - для работы с OpenAI API
- `langchain` - для создания LLM-приложений
- `node-fetch` - HTTP-клиент для работы с REST API
- `form-data` - формирование multipart/form-data запросов
- `cheerio` - серверный парсинг и обработка HTML

#### Обработка изображений и мультимедиа

- `sharp` - высокопроизводительная обработка изображений
- `@ffmpeg/ffmpeg` - работа с видео и аудио
- `gm` - обработка изображений через GraphicsMagick/ImageMagick
- `image-size` - определение размера и типа изображений
- `heic-convert` - конвертация HEIC (iPhone) в JPEG/PNG
- `tesseract.js` - оптическое распознавание текста на изображениях

#### Работа с документами

- `pdf-lib` - создание, редактирование и анализ PDF-документов
- `pdf-parse` - извлечение текстового/метаданных из PDF
- `xlsx` - работа с Excel-файлами (XLSX, CSV)
- `exceljs` - более гибкая работа с Excel, создание сложных таблиц
- `mammoth` - преобразование DOCX в HTML/Markdown/Plain text
- `@shelf/aws-lambda-libreoffice` - конвертация офисных документов в PDF/HTML
- `html-pdf` - генерация PDF из HTML-шаблонов
- `csv-parse` - чтение и парсинг CSV-файлов

#### Работа с архивами и файлами

- `jszip` - чтение и создание ZIP-архивов
- `archiver` - создание ZIP, TAR и других архивов на лету
- `unzipper` - распаковка ZIP-архивов
- И многие другие npm-пакеты

## Установка и настройка

### Предварительные требования

- Docker и Docker Compose
- Доступ к командной строке сервера
- Базовые знания JavaScript и npm

### Процесс установки

В нашей системе уже настроен кастомный образ n8n с предустановленными библиотеками и хелперами. При запуске системы через скрипт `setup.sh` или `setup-files/07-start-services.sh` автоматически создаются все необходимые тома Docker и запускается n8n с расширенными возможностями.

### Проверка установки

Чтобы убедиться, что система настроена правильно, выполните следующую команду:

```bash
sudo ./setup-files/n8n-packages.sh list
```

Эта команда выведет список всех установленных npm-пакетов в n8n.

## Управление библиотеками

Для управления библиотеками в n8n используется специальный скрипт `n8n-packages.sh`, который находится в директории `setup-files`.

### Установка новой библиотеки

```bash
sudo ./setup-files/n8n-packages.sh install <имя-пакета> [версия]
```

Например:

```bash
sudo ./setup-files/n8n-packages.sh install lodash
sudo ./setup-files/n8n-packages.sh install axios@1.4.0
```

### Удаление библиотеки

```bash
sudo ./setup-files/n8n-packages.sh remove <имя-пакета>
```

Например:

```bash
sudo ./setup-files/n8n-packages.sh remove lodash
```

### Обновление библиотек

Для обновления всех библиотек:

```bash
sudo ./setup-files/n8n-packages.sh update
```

Для обновления конкретной библиотеки:

```bash
sudo ./setup-files/n8n-packages.sh update <имя-пакета>
```

### Просмотр списка установленных библиотек

```bash
sudo ./setup-files/n8n-packages.sh list
```

## Использование библиотек в узле Code

После установки библиотеки её можно использовать в узле Code n8n. Для этого просто импортируйте библиотеку с помощью `require`:

```javascript
// Импорт библиотеки
const axios = require('axios');
const _ = require('lodash');
const moment = require('moment');

// Использование библиотеки
const response = await axios.get('https://api.example.com/data');
const sortedData = _.sortBy(response.data, 'name');
const formattedDate = moment().format('YYYY-MM-DD');

// Возвращение результата
return {
  data: sortedData,
  date: formattedDate
};
```

## Встроенные хелперы

Для упрощения работы с некоторыми библиотеками в системе предустановлены специальные хелперы. Они находятся в директории `/home/node/.n8n/custom_modules` внутри контейнера n8n и доступны для импорта в узле Code.

Ниже приведены примеры использования различных хелперов:

### Хелпер для работы с Qdrant

```javascript
// Импорт хелпера для Qdrant
const { QdrantHelper } = require('/home/node/.n8n/custom_modules');

// Создание экземпляра хелпера
const qdrant = new QdrantHelper({
  url: 'http://qdrant:6333',
  apiKey: 'your-api-key' // Опционально
});

// Поиск по векторам
const searchResults = await qdrant.search('my-collection', vector, 5);

// Возвращение результата
return {
  results: searchResults
};
```

### Хелпер для работы с Mem0

```javascript
// Импорт хелпера для Mem0
const { Mem0Helper } = require('/home/node/.n8n/custom_modules');

// Создание экземпляра хелпера
const mem0 = new Mem0Helper({
  url: 'http://mem0:3000',
  apiKey: 'your-api-key'
});

// Создание воспоминания
const memory = await mem0.createMemory({
  user_id: 'user123',
  content: 'Пользователь предпочитает получать уведомления по email',
  type: 'preference'
});

// Возвращение результата
return {
  memory: memory
};
```

### Хелпер для работы с изображениями

```javascript
// Импорт хелпера для работы с изображениями
const { ImageHelper } = require('/home/node/.n8n/custom_modules');

// Создание экземпляра хелпера
const imageHelper = new ImageHelper();

// Получение данных из предыдущего узла
const imageBuffer = $input.item.binary.data.buffer;

// Изменение размера изображения
const resizedImage = await imageHelper.resize(imageBuffer, {
  width: 800,
  height: 600,
  fit: 'contain',
  format: 'jpeg',
  quality: 80
});

// Распознавание текста на изображении (OCR)
const recognizedText = await imageHelper.recognizeText(imageBuffer, {
  lang: 'rus+eng' // Русский и английский языки
});

// Возвращение результата
return {
  resizedImage: resizedImage,
  text: recognizedText,
  // Для использования в бинарном выходе
  binary: {
    data: {
      fileName: 'resized.jpg',
      mimeType: 'image/jpeg',
      data: resizedImage.toString('base64')
    }
  }
};
```

### Хелпер для работы с документами

```javascript
// Импорт хелпера для работы с документами
const { DocumentHelper } = require('/home/node/.n8n/custom_modules');

// Создание экземпляра хелпера
const docHelper = new DocumentHelper();

// Получение данных из предыдущего узла
const pdfBuffer = $input.item.binary.data.buffer;

// Извлечение текста из PDF
const extractedText = await docHelper.extractTextFromPdf(pdfBuffer);

// Создание Excel-файла с данными
const data = [
  { name: 'Иван', age: 30, city: 'Москва' },
  { name: 'Мария', age: 25, city: 'Санкт-Петербург' },
  { name: 'Алексей', age: 35, city: 'Новосибирск' }
];

const excelBuffer = await docHelper.createExcel(data, { sheet: 'Сотрудники' });

// Преобразование HTML в PDF
const html = `
  <html>
    <body>
      <h1>Отчет</h1>
      <p>Это пример отчета, сгенерированного с помощью n8n.</p>
      <p>Извлеченный текст: ${extractedText.substring(0, 500)}...</p>
    </body>
  </html>
`;

const pdfFromHtml = await docHelper.htmlToPdf(html);

// Возвращение результата
return {
  text: extractedText,
  binary: {
    excel: {
      fileName: 'data.xlsx',
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      data: excelBuffer.toString('base64')
    },
    pdf: {
      fileName: 'report.pdf',
      mimeType: 'application/pdf',
      data: pdfFromHtml.toString('base64')
    }
  }
};
```

### Хелпер для работы с архивами

```javascript
// Импорт хелпера для работы с архивами
const { ArchiveHelper } = require('/home/node/.n8n/custom_modules');

// Создание экземпляра хелпера
const archiveHelper = new ArchiveHelper();

// Подготовка файлов для архивации
const files = [
  {
    name: 'report.txt',
    content: 'Это отчет за прошлый месяц.'
  },
  {
    name: 'data.json',
    content: JSON.stringify({ users: 100, active: 75, inactive: 25 })
  },
  {
    name: 'config.ini',
    content: '[settings]\nmode=production\ndebug=false'
  }
];

// Создание ZIP-архива
const zipBuffer = await archiveHelper.createZip(files);

// Чтение содержимого архива
const zipContent = await archiveHelper.readZip(zipBuffer);

// Возвращение результата
return {
  fileCount: Object.keys(zipContent).length,
  fileList: Object.keys(zipContent),
  binary: {
    zip: {
      fileName: 'archive.zip',
      mimeType: 'application/zip',
      data: zipBuffer.toString('base64')
    }
  }
};
```

## Примеры использования

### Пример 1: Работа с API через axios

```javascript
// Импорт библиотеки
const axios = require('axios');

// Получение данных из предыдущего узла
const { apiKey, query } = $input.all()[0];

// Выполнение запроса к API
try {
  const response = await axios.get('https://api.example.com/search', {
    params: { q: query },
    headers: { 'Authorization': `Bearer ${apiKey}` }
  });
  
  // Обработка ответа
  return {
    success: true,
    data: response.data,
    count: response.data.length
  };
} catch (error) {
  return {
    success: false,
    error: error.message
  };
}
```

### Пример 2: Интеграция с Qdrant и OpenAI

```javascript
// Импорт библиотек и хелперов
const { QdrantHelper } = require('/home/node/.n8n/custom_modules');
const { OpenAI } = require('openai');

// Получение данных из предыдущего узла
const { query, apiKey } = $input.all()[0];

// Инициализация клиентов
const openai = new OpenAI({ apiKey });
const qdrant = new QdrantHelper({ url: 'http://qdrant:6333' });

// Создание эмбеддинга для запроса
const embeddingResponse = await openai.embeddings.create({
  model: 'text-embedding-ada-002',
  input: query
});
const queryVector = embeddingResponse.data[0].embedding;

// Поиск похожих документов в Qdrant
const searchResults = await qdrant.search('documents', queryVector, 5);

// Формирование контекста из найденных документов
const context = searchResults.map(result => result.payload.content).join('\n\n');

// Отправка запроса к OpenAI с контекстом
const completion = await openai.chat.completions.create({
  model: 'gpt-3.5-turbo',
  messages: [
    { role: 'system', content: 'Ты — полезный ассистент.' },
    { role: 'user', content: `Контекст: ${context}\n\nВопрос: ${query}` }
  ]
});

// Возвращение результата
return {
  answer: completion.choices[0].message.content,
  context: context,
  sources: searchResults.map(result => ({
    id: result.id,
    title: result.payload.title,
    relevance: result.score
  }))
};
```

### Пример 3: Работа с датами через moment

```javascript
// Импорт библиотеки
const moment = require('moment');

// Получение данных из предыдущего узла
const { startDate, endDate, format } = $input.all()[0];

// Настройка локали (опционально)
moment.locale('ru');

// Работа с датами
const start = moment(startDate);
const end = moment(endDate);
const duration = moment.duration(end.diff(start));

// Форматирование дат
const formattedStart = start.format(format || 'DD.MM.YYYY');
const formattedEnd = end.format(format || 'DD.MM.YYYY');

// Расчет разницы
const days = duration.asDays();
const hours = duration.asHours();

// Возвращение результата
return {
  formattedStart,
  formattedEnd,
  difference: {
    days: Math.floor(days),
    hours: Math.floor(hours),
    minutes: Math.floor(duration.asMinutes())
  },
  humanized: duration.humanize()
};
```

### Пример 4: Комбинированное использование хелперов

```javascript
// Импорт всех необходимых хелперов
const { 
  ImageHelper, 
  DocumentHelper, 
  ArchiveHelper, 
  Mem0Helper 
} = require('/home/node/.n8n/custom_modules');

// Создание экземпляров хелперов
const imageHelper = new ImageHelper();
const docHelper = new DocumentHelper();
const archiveHelper = new ArchiveHelper();
const mem0 = new Mem0Helper({
  url: 'http://mem0:3000',
  apiKey: process.env.MEM0_API_KEY
});

// Получение данных из предыдущего узла
const { userId, imageBuffer, documentType } = $input.all()[0];

// Основной процесс обработки
async function processDocument() {
  // Распознавание текста на изображении
  const recognizedText = await imageHelper.recognizeText(imageBuffer);
  
  // Сохранение текста в Mem0
  await mem0.createMemory({
    user_id: userId,
    content: recognizedText,
    type: 'document',
    metadata: {
      documentType: documentType,
      processedAt: new Date().toISOString()
    }
  });
  
  // Создание PDF с извлеченным текстом
  const html = `
    <html>
      <body>
        <h1>Распознанный текст</h1>
        <p>${recognizedText.replace(/\n/g, '<br>')}</p>
      </body>
    </html>
  `;
  
  const pdfBuffer = await docHelper.htmlToPdf(html);
  
  // Создание архива с исходным изображением и PDF
  const files = [
    {
      name: 'original.jpg',
      content: imageBuffer
    },
    {
      name: 'recognized.pdf',
      content: pdfBuffer
    },
    {
      name: 'text.txt',
      content: recognizedText
    }
  ];
  
  const zipBuffer = await archiveHelper.createZip(files);
  
  return {
    text: recognizedText,
    binary: {
      archive: {
        fileName: `${documentType}_${userId}.zip`,
        mimeType: 'application/zip',
        data: zipBuffer.toString('base64')
      }
    }
  };
}

// Выполнение основного процесса
return await processDocument();
```

## Часто задаваемые вопросы

### Какие библиотеки уже предустановлены?

Для просмотра списка предустановленных библиотек выполните команду:

```bash
sudo ./setup-files/n8n-packages.sh list
```

В системе предустановлены следующие категории библиотек:

1. **Базовые библиотеки**: axios, lodash, moment, node-fetch, form-data, cheerio
2. **Работа с AI**: openai, langchain, @qdrant/js-client-rest
3. **Обработка изображений**: sharp, @ffmpeg/ffmpeg, gm, image-size, heic-convert, tesseract.js
4. **Работа с документами**: pdf-lib, pdf-parse, xlsx, exceljs, mammoth, html-pdf, csv-parse
5. **Работа с архивами**: jszip, archiver, unzipper

### Как добавить свой хелпер?

1. Создайте JavaScript файл с вашим хелпером в директории `/home/den/cloud-local-n8n-flowise/n8n-custom/helpers/`
2. Обновите файл `/home/den/cloud-local-n8n-flowise/n8n-custom/helpers/index.js`, чтобы экспортировать ваш хелпер
3. Перестройте и перезапустите контейнер n8n:

```bash
sudo docker compose -f /opt/n8n-docker-compose.yaml build n8n
sudo docker compose -f /opt/n8n-docker-compose.yaml up -d n8n
```

### Что делать, если библиотека не устанавливается?

1. Проверьте, что контейнер n8n запущен
2. Проверьте наличие ошибок при установке
3. Попробуйте установить конкретную версию библиотеки
4. Проверьте совместимость библиотеки с Node.js версии, используемой в n8n

### Как использовать TypeScript в узле Code?

n8n поддерживает TypeScript в узле Code из коробки. Просто выберите TypeScript в качестве языка при создании узла Code.

### Сохраняются ли установленные библиотеки после перезапуска?

Да, все установленные библиотеки сохраняются в томе Docker `n8n_modules` и будут доступны после перезапуска контейнера или сервера.

### Как обновить все библиотеки сразу?

```bash
sudo ./setup-files/n8n-packages.sh update
```

### Можно ли использовать библиотеки, требующие компиляцию нативных модулей?

Да, но для этого может потребоваться дополнительная настройка. В некоторых случаях может потребоваться установка дополнительных системных зависимостей в Dockerfile.
