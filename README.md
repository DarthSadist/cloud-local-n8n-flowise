# Автоматическая установка n8n, Flowise, Qdrant и других сервисов

Этот проект представляет собой набор скриптов для автоматизированной установки и настройки стека сервисов для работы с AI и автоматизацией рабочих процессов. Все сервисы развертываются в Docker-контейнерах и доступны через безопасные HTTPS-соединения благодаря Caddy.

## Включенные сервисы

- **n8n** - платформа автоматизации рабочих процессов с низкокодовым интерфейсом
  - Настроена для использования PostgreSQL для постоянного хранения данных
  - Включает Redis для очередей и кеширования
- **Flowise** - интерфейс для создания LLM-приложений и чат-цепочек
- **Qdrant** - векторная база данных для хранения и поиска эмбеддингов
  - Защищен API-ключом для безопасного доступа
- **Crawl4AI** - веб-сервис для сбора данных и их обработки
- **WordPress** - популярная CMS для создания веб-сайтов и блогов
  - Настроена с MariaDB для хранения данных
  - Оптимизирована для производительности и безопасности
- **PostgreSQL** - реляционная база данных с расширением pgvector
- **Adminer** - веб-интерфейс для управления базами данных
- **Caddy** - веб-сервер с автоматическим получением SSL-сертификатов
- **Watchtower** - сервис для автоматического обновления Docker-контейнеров
- **Netdata** - система мониторинга в реальном времени

## Подробное описание сервисов

### n8n
[n8n](https://n8n.io/docs/) - это мощная платформа автоматизации рабочих процессов с открытым исходным кодом, позволяющая соединять различные сервисы и API без написания кода:
- Низкокодовый визуальный редактор для создания рабочих процессов (workflow)
- Поддержка более 300+ интеграций с популярными сервисами и API
- Возможность создания собственных узлов и расширений с помощью JavaScript/TypeScript
- Исполнение рабочих процессов по расписанию, webhook или триггерам
- Возможность запуска как в облаке, так и локально
- В этой установке настроена работа с PostgreSQL для надежного хранения данных
- Интеграция с Redis для улучшения производительности, кеширования и обработки очередей
- Предусмотрена система пользователей с разграничением доступа к workspaces
- [Примеры рабочих процессов](https://n8n.io/workflows/)

### Flowise
[Flowise](https://github.com/FlowiseAI/Flowise) - это инструмент с открытым исходным кодом для создания настраиваемых AI-приложений и цепочек взаимодействия с LLM:
- Визуальный конструктор для создания чат-ботов и LLM-приложений без написания кода
- Поддержка различных моделей и провайдеров LLM (OpenAI, Anthropic, Llama, Mistral и др.)
- Интеграция с векторными базами данных, включая Qdrant, Pinecone, Weaviate
- Возможность создания и обучения собственных AI-агентов с памятью и инструментами
- Предоставляет RESTful API и WebSocket для интеграции созданных решений
- Управление контекстом и памятью для долгих диалогов
- Полная совместимость с LangChain.js и интерфейсом Chains 
- Поддержка встраивания в существующие веб-приложения через iframe
- [Документация по API](https://docs.flowiseai.com/)

### Qdrant
[Qdrant](https://qdrant.tech/documentation/) - это современная векторная база данных, специально разработанная для систем поиска по семантическому сходству:
- Высокопроизводительное хранение и поиск векторных эмбеддингов с низкой латентностью
- Поддержка фильтрации при векторном поиске для сложных условий выборки
- Масштабируемость и производительность для больших наборов данных (миллиарды векторов)
- Встроенный веб-интерфейс (Dashboard) для визуального управления коллекциями и точками данных
  - Доступен по адресу https://qdrant.ваш-домен.com/dashboard/
  - Защищен API-ключом, который генерируется при установке
  - Позволяет создавать коллекции, выполнять поисковые запросы и просматривать статистику
- Возможность горизонтального масштабирования через кластеры
- Защита API с помощью ключей для безопасного доступа
- Поддержка различных метрик расстояния: Евклидово, Косинусное, Dot-product
- Управление метаданными и полями для каждого вектора
- Возможность обновления, удаления и добавления векторов без перестроения индексов
- Интегрируется с Flowise и n8n для построения векторных хранилищ знаний
- [Учебные материалы и примеры](https://qdrant.tech/documentation/tutorials/)

### PostgreSQL с pgvector
[PostgreSQL](https://www.postgresql.org/docs/) с расширением [pgvector](https://github.com/pgvector/pgvector) - это мощная объектно-реляционная система управления базами данных с поддержкой векторных вычислений:
- Надежное хранение структурированных данных для n8n и других сервисов
- Расширение pgvector для работы с векторными эмбеддингами и семантическим поиском
- Поддержка транзакций, триггеров, представлений и хранимых процедур
- Богатая экосистема инструментов и расширений
- Поддержка индексов HNSW для быстрого поиска ближайших соседей
- Возможность комбинирования традиционных SQL-запросов с векторным поиском
- Масштабируемость и высокая производительность
- Совместимость с многочисленными инструментами для анализа и визуализации данных
- [Документация pgvector](https://github.com/pgvector/pgvector/blob/master/README.md)

### Crawl4AI
Crawl4AI - это веб-сервис, предназначенный для сбора данных из различных источников для AI-приложений. В текущей конфигурации он представлен как базовый API-эндпоинт, который может использоваться как отправная точка для интеграций:

- Простой API-эндпоинт с информацией о статусе сервиса
- Защита доступа с помощью JWT-аутентификации
- Интеграция с общей сетью Docker для взаимодействия с другими сервисами
- Возможность расширения функциональности через n8n и Flowise
- Легковесная конфигурация с минимальным потреблением ресурсов

#### Практическое применение Crawl4AI в текущей конфигурации

Несмотря на минимальную реализацию, Crawl4AI может быть эффективно использован в различных сценариях:

##### 1. Мониторинг состояния стека в n8n

```javascript
// Пример рабочего процесса n8n для мониторинга сервисов
// В узле Function используйте этот код:
async function checkServices() {
  const services = [
    { name: 'Crawl4AI', url: 'https://crawl4ai.ваш-домен.com/' },
    { name: 'n8n', url: 'https://n8n.ваш-домен.com/healthz' },
    { name: 'Flowise', url: 'https://flowise.ваш-домен.com/api/health' }
  ];
  
  const results = [];
  for (const service of services) {
    try {
      const response = await $http.request({ url: service.url, method: 'GET' });
      const statusOk = response.statusCode === 200;
      results.push({
        service: service.name,
        status: statusOk ? 'online' : 'offline',
        details: response.data
      });
    } catch (error) {
      results.push({
        service: service.name,
        status: 'error',
        details: error.message
      });
    }
  }
  return { serviceStatus: results };
}

return await checkServices();
```

##### 2. Использование как базового API в Flowise

Вы можете интегрировать Crawl4AI с Flowise для создания более сложных AI-приложений:

```javascript
// Код для JavaScript-узла в Flowise:
async function fetchServiceStatus() {
  const response = await fetch('https://crawl4ai.ваш-домен.com/');
  const data = await response.json();
  
  // Проверяем, работает ли сервис
  if (data.status === 'ok') {
    // Здесь можно добавить собственную логику скрапинга
    // или использовать другие интеграции
    return {
      systemStatus: 'Все системы работают нормально',
      crawl4aiVersion: data.version,
      timestamp: new Date().toISOString()
    };
  } else {
    return {
      systemStatus: 'Обнаружена проблема в работе сервиса',
      error: 'Crawl4AI не отвечает должным образом'
    };
  }
}

return await fetchServiceStatus();
```

##### 3. Создание агрегатора данных с использованием n8n

Используйте n8n для сбора данных, а Crawl4AI как точку интеграции:

```bash
# Пример команды для запуска рабочего процесса n8n через CLI:
n8n execute --workflow "Web Scraper" --destinationUrl "https://crawl4ai.ваш-домен.com/" --authToken "${CRAWL4AI_JWT_SECRET}"
```

##### 4. Расширение через монтирование собственного кода

Вы можете расширить функциональность Crawl4AI, добавив собственный код в контейнер:

```yaml
# Пример модификации crawl4ai-docker-compose.yaml:
services:
  crawl4ai:
    # ... существующие настройки
    volumes:
      - ./custom-scripts:/app/scripts
    command: ["/bin/sh", "-c", "cd /app && npm install express axios cheerio && node /app/scripts/server.js"]
```

```javascript
// Пример server.js для расширенной функциональности:
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.json({ status: 'ok', service: 'crawl4ai', version: '1.0' });
});

app.get('/api/scrape', (req, res) => {
  // Здесь можно добавить логику веб-скрапинга
  res.json({ message: 'Endpoint для скрапинга' });
});

app.listen(8000, () => {
  console.log('Crawl4AI API запущен на порту 8000');
});
```

##### 5. Работа с внешними источниками данных

Ниже приведены примеры использования Crawl4AI с n8n и Flowise для работы с внешними источниками данных:

###### a) Сбор данных с новостных сайтов (n8n)

```javascript
// Пример рабочего процесса n8n для сбора новостей
// В узле HTTP Request:
// URL: https://example-news-site.com
// Далее в узле HTML Extract:
// Селектор: article .headline
// Затем в узле Function:

// Форматирование результатов
const formatted = {
  source: 'example-news-site',
  timestamp: new Date().toISOString(),
  headlines: $input.item.extracted || []
};

// Отправка данных в Crawl4AI (для сохранения в журнале или обработки)
return {
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + process.env.CRAWL4AI_JWT_SECRET
  },
  url: 'https://crawl4ai.ваш-домен.com/',
  method: 'POST',
  body: formatted
};
```

###### b) Мониторинг RSS-каналов (n8n)

```javascript
// В n8n создайте следующий рабочий процесс:
// 1. Триггер Schedule: каждый час
// 2. Узел RSS Read Feed: настройте URL вашего RSS-канала
// 3. Узел Function (код ниже):

function processFeed(items) {
  if (!Array.isArray(items) || items.length === 0) return [];
  
  return items.map(item => ({
    title: item.title,
    link: item.link,
    published: item.pubDate || item.published,
    content: item.content || item.description,
    source: new URL(item.link).hostname,
    collected: new Date().toISOString()
  }));
}

const processedItems = processFeed($input.all[0].json.items);

// Отправка данных в Qdrant через Crawl4AI
const payload = {
  operation: 'store_rss',
  data: processedItems,
  metadata: {
    source_type: 'rss',
    total_items: processedItems.length
  }
};

return { json: payload };

// 4. Узел HTTP Request для отправки данных в Crawl4AI
```

###### c) Интеграция с API внешних сервисов (Flowise)

```javascript
// Код для JavaScript-узла в Flowise
async function fetchWeatherData() {
  // Запрос к публичному API погоды
  const response = await fetch('https://api.weatherapi.com/v1/current.json?key=YOUR_API_KEY&q=Moscow');
  const weatherData = await response.json();
  
  // Форматируем данные
  const formattedData = {
    location: weatherData.location.name,
    country: weatherData.location.country,
    temperature: weatherData.current.temp_c,
    condition: weatherData.current.condition.text,
    timestamp: new Date().toISOString()
  };
  
  // Отправляем данные в Crawl4AI для кэширования/хранения
  try {
    await fetch('https://crawl4ai.ваш-домен.com/api/data', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + process.env.CRAWL4AI_JWT_SECRET
      },
      body: JSON.stringify({
        source: 'weather_api',
        data: formattedData
      })
    });
    
    return formattedData;
  } catch (error) {
    console.error('Failed to store data in Crawl4AI:', error);
    return formattedData; // Возвращаем данные все равно
  }
}

return await fetchWeatherData();
```

###### d) Сбор данных с GitHub и интеграция с Qdrant

```javascript
// Пример для n8n, работающего с GitHub API и интегрирующего с Qdrant
// В Function ноде:

async function fetchGitHubRepos() {
  // Запрос к GitHub API
  const response = await $http.request({
    url: 'https://api.github.com/users/YOUR_USERNAME/repos',
    method: 'GET',
    headers: {
      'User-Agent': 'n8n-crawl4ai-integration'
    }
  });
  
  // Обрабатываем данные о репозиториях
  const repos = response.data.map(repo => ({
    name: repo.name,
    description: repo.description || '',
    url: repo.html_url,
    stars: repo.stargazers_count,
    language: repo.language,
    created_at: repo.created_at,
    updated_at: repo.updated_at
  }));
  
  // Формируем данные для отправки в Crawl4AI
  return {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + process.env.CRAWL4AI_JWT_SECRET
    },
    url: 'https://crawl4ai.ваш-домен.com/api/github-data',
    method: 'POST',
    body: JSON.stringify({
      source: 'github_api',
      data: repos,
      timestamp: new Date().toISOString(),
      // Параметры для сохранения в Qdrant через прокси Crawl4AI
      qdrant: {
        collection_name: 'github_repos',
        vector_dimension: 384,  // Размерность вектора, зависит от модели эмбеддингов
        embed_field: 'description'  // Поле, которое будет использовано для создания эмбеддингов
      }
    })
  };
}

return await fetchGitHubRepos();
```

### Adminer
[Adminer](https://www.adminer.org/) - легковесный инструмент для управления базами данных через веб-интерфейс:
- Позволяет управлять базой данных PostgreSQL через браузер
- Поддержка выполнения SQL-запросов и просмотра результатов
- Возможность экспорта и импорта данных
- Просмотр и редактирование структуры таблиц
- Управление индексами, внешними ключами и пользователями
- Поддержка множества типов баз данных (MySQL, PostgreSQL, SQLite, MS SQL, Oracle)
- Компактный размер и высокая производительность
- [Документация и руководства](https://www.adminer.org/en/doc/)

### Caddy
[Caddy](https://caddyserver.com/docs/) - это современный веб-сервер с автоматическим HTTPS:
- Автоматическое получение и обновление SSL-сертификатов от Let's Encrypt
- Выступает в роли обратного прокси для всех сервисов в стеке
- Простая и понятная конфигурация без сложных директив
- Встроенная поддержка HTTP/2 и HTTP/3
- Высокая производительность и безопасность по умолчанию
- Поддержка статических файлов и динамического контента
- Встроенные средства кеширования и сжатия
- [Руководство по Caddyfile](https://caddyserver.com/docs/caddyfile-tutorial)

### Watchtower
[Watchtower](https://containrrr.dev/watchtower/) - это сервис для автоматического обновления Docker-контейнеров:
- Отслеживает обновления образов Docker для всех установленных сервисов
- Автоматически обновляет контейнеры до последних версий с минимальным простоем
- Настраиваемый график обновлений (по умолчанию — ежедневно в 4:00)
- Уведомления о результатах обновлений через различные каналы
- Поддержка Docker Swarm и Kubernetes
- Гибкое управление через метки контейнеров
- Минимальное потребление ресурсов в режиме ожидания
- [Примеры конфигурации](https://containrrr.dev/watchtower/examples/)

### WordPress
[WordPress](https://wordpress.org/documentation/) - самая популярная в мире система управления контентом, которая позволяет создавать сайты различной сложности:
- Интуитивно понятный интерфейс для создания и управления контентом
- Широкая экосистема плагинов и тем для расширения функциональности
- Встроенная система SEO и инструменты для оптимизации поискового продвижения
- Гибкая система управления пользователями и правами доступа
- Поддержка множества типов контента: блоги, страницы, медиа-файлы
- Возможность создания интернет-магазинов через WooCommerce
- Регулярные обновления безопасности и функциональности
- В этой установке WordPress настроен с MariaDB для надежного хранения данных
- Оптимизирован для производительности и безопасности с помощью специальных скриптов
- Интегрируется с n8n посредством плагинов и REST API
- [WordPress руководство пользователя](https://wordpress.org/support/)

### Netdata
[Netdata](https://learn.netdata.cloud/docs/) - система мониторинга производительности в реальном времени:
- Отслеживает тысячи метрик системы, приложений и контейнеров с секундной гранулярностью
- Предоставляет интерактивные дашборды с графиками производительности в реальном времени
- Автоматически определяет аномалии и потенциальные проблемы
- Имеет крайне низкие накладные расходы на мониторинг (менее 1% CPU)
- Не требует сложной настройки — работает "из коробки"
- Отслеживает состояние Docker-контейнеров и их ресурсов
- Поддерживает предупреждения и уведомления о проблемах
- Возможность экспорта метрик в другие системы мониторинга
- [Руководство по мониторингу Docker](https://learn.netdata.cloud/docs/agent/packaging/docker)

## Системные требования

### Минимальные требования

- **Операционная система**: Ubuntu 22.04 LTS или другой совместимый дистрибутив Linux
- **Процессор**: 2 виртуальных ядра (vCPU) с частотой от 2 GHz
- **Оперативная память**: 4 ГБ RAM
- **Дисковое пространство**: минимум 25 ГБ
  - n8n + PostgreSQL + Redis: ~10 ГБ
  - Flowise: ~2 ГБ
  - Qdrant: ~2 ГБ
  - WordPress + MariaDB: ~5 ГБ
  - Система и прочие сервисы: ~6 ГБ
- **Сеть**: стабильное подключение к интернету
- **Домен**: настроенное доменное имя, указывающее на IP вашего сервера
- **Порты**: открытые порты 80 и 443

### Рекомендуемые (оптимальные) ресурсы

- **Процессор**: 4 виртуальных ядра (vCPU) с частотой от 2.4 GHz
- **Оперативная память**: 8 ГБ RAM
- **Дисковое пространство**: 40+ ГБ SSD
  - Основное пространство: 30 ГБ
  - Дополнительные 10+ ГБ для резервных копий и роста данных
- **Сеть**: выделенный IP-адрес и пропускная способность не менее 50 Мбит/с

### Примечания по нагрузке

- **Пиковая нагрузка на CPU**:
  - n8n: до 80% при запуске интенсивных рабочих процессов
  - Flowise: до 70% при генерации сложных ответов
  - WordPress: 20-30% при множественных одновременных запросах

- **Использование памяти**:
  - n8n + Redis + PostgreSQL: 1.5-2 ГБ
  - Flowise: 500-700 МБ
  - WordPress + MariaDB: 500-800 МБ
  - Qdrant: 300-500 МБ
  - Прочие сервисы: ~500 МБ

При интенсивном использовании всех сервисов одновременно рекомендуется сервер с 8 ГБ RAM и 4+ vCPU.

## Быстрая установка

1. Клонируйте репозиторий:
   ```bash
   git clone https://github.com/DarthSadist/cloud-local-n8n-flowise.git
   cd cloud-local-n8n-flowise
   ```

2. Запустите установочный скрипт:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. Следуйте инструкциям в терминале:
   - Введите ваше доменное имя
   - Укажите email для Let's Encrypt и авторизации в n8n
   - Подтвердите часовой пояс

## Доступ к сервисам

После успешной установки сервисы будут доступны по следующим адресам:

- **n8n**: https://n8n.ваш-домен
- **Flowise**: https://flowise.ваш-домен
- **WordPress**: https://wordpress.ваш-домен
- **Adminer**: https://adminer.ваш-домен
- **Qdrant**: https://qdrant.ваш-домен
- **Crawl4AI**: https://crawl4ai.ваш-домен
- **Netdata**: https://netdata.ваш-домен

## Учетные данные

Все учетные данные генерируются автоматически и сохраняются в файле `/opt/.env`. В конце установки вам будут показаны основные логины и пароли.

### Для n8n:
- **Логин**: email, указанный при установке
- **Пароль**: автоматически сгенерированный (см. в `/opt/.env`)

### Для Flowise:
- **Логин**: admin
- **Пароль**: автоматически сгенерированный (см. в `/opt/.env`)

### Для PostgreSQL (через Adminer):
- **Сервер**: postgres
- **Имя пользователя**: n8n
- **Пароль**: автоматически сгенерированный (см. в `/opt/.env`)
- **База данных**: n8n

### Для Qdrant:
- **API-ключ**: автоматически сгенерированный (см. в `/opt/.env`)

### Для Crawl4AI:
- **JWT-секрет**: автоматически сгенерированный (см. в `/opt/.env`)

### Для WordPress:
- **Начальная настройка**: при первом запуске необходимо создать учетную запись администратора
- **Доступ к базе данных**: параметры доступа к MariaDB хранятся в `/opt/.env` (WP_DB_USER, WP_DB_PASSWORD)

## Управление сервисами

### Проверка статуса контейнеров
```bash
sudo docker ps
```

### Перезапуск сервисов
```bash
# Перезапуск n8n и связанных сервисов (PostgreSQL, Redis, Caddy)
sudo docker compose -f /opt/n8n-docker-compose.yaml --env-file /opt/.env restart

# Перезапуск Flowise
sudo docker compose -f /opt/flowise-docker-compose.yaml --env-file /opt/.env restart

# Перезапуск WordPress и связанных сервисов
sudo docker compose -f /opt/wordpress-docker-compose.yaml --env-file /opt/.env restart

# Перезапуск Qdrant
sudo docker compose -f /opt/qdrant-docker-compose.yaml --env-file /opt/.env restart

# Перезапуск Crawl4AI
sudo docker compose -f /opt/crawl4ai-docker-compose.yaml --env-file /opt/.env restart

# Перезапуск Watchtower
sudo docker compose -f /opt/watchtower-docker-compose.yaml restart

# Перезапуск Netdata
sudo docker compose -f /opt/netdata-docker-compose.yaml restart
```

### Доступ к веб-интерфейсу Qdrant

Qdrant имеет встроенный веб-интерфейс (Dashboard), который позволяет управлять коллекциями, точками данных и выполнять поисковые запросы через визуальный интерфейс.

#### Как получить доступ к Dashboard

1. **URL для доступа**: 
   ```
   https://qdrant.ваш-домен.com/dashboard/
   ```
   Обратите внимание на обязательный слеш `/` в конце URL.

2. **Аутентификация**:
   - При первом входе вам потребуется указать API-ключ Qdrant
   - API-ключ генерируется автоматически при установке и выводится в конце работы скрипта `setup.sh`
   - Вы также можете найти API-ключ в файле `/opt/.env` в параметре `QDRANT_API_KEY`:
     ```bash
     grep QDRANT_API_KEY /opt/.env
     ```

3. **Основные возможности**:
   - Создание и настройка коллекций векторов
   - Управление точками данных (добавление, просмотр, поиск)
   - Визуализация метаданных и статистики
   - Выполнение пробных поисковых запросов
   - Настройка параметров индексирования

4. **Примечания**:
   - Через Dashboard можно выполнять все те же операции, что и через REST API
   - Для продуктивной работы рекомендуется использовать программный доступ через клиентские библиотеки
   - Документацию по REST API Qdrant можно посмотреть по адресу:
     ```
     https://qdrant.ваш-домен.com/docs
     ```

### Остановка сервисов
```bash
sudo docker compose -f /opt/n8n-docker-compose.yaml --env-file /opt/.env down
sudo docker compose -f /opt/flowise-docker-compose.yaml --env-file /opt/.env down
sudo docker compose -f /opt/qdrant-docker-compose.yaml --env-file /opt/.env down
sudo docker compose -f /opt/crawl4ai-docker-compose.yaml --env-file /opt/.env down
sudo docker compose -f /opt/watchtower-docker-compose.yaml down
sudo docker compose -f /opt/netdata-docker-compose.yaml down
```

### Просмотр логов
```bash
# Просмотр логов n8n
sudo docker logs n8n

# Просмотр логов Flowise
sudo docker logs flowise

# Просмотр логов Qdrant
sudo docker logs qdrant

# Просмотр логов WordPress
sudo docker logs wordpress

# Просмотр логов базы данных WordPress
sudo docker logs wordpress_db

# Просмотр логов Caddy
sudo docker logs caddy
```

## Установка и настройка WordPress

WordPress устанавливается автоматически вместе с основным стеком сервисов. Если вы хотите использовать WordPress отдельно или настроить его после установки основного пакета, следуйте этой пошаговой инструкции.

### Первоначальная настройка WordPress

После установки основного пакета WordPress будет доступен по адресу `https://wordpress.ваш-домен`, но потребуется выполнить первоначальную настройку:

1. **Откройте веб-браузер** и перейдите по адресу: `https://wordpress.ваш-домен`

2. **Выберите язык** для вашей установки WordPress и нажмите "Продолжить"

3. **Создайте учетную запись администратора**:
   - Введите название сайта (можно изменить позже)
   - Создайте имя пользователя администратора (не используйте "admin" по соображениям безопасности)
   - Задайте надежный пароль (рекомендуется использовать предложенный системой)
   - Введите ваш email для восстановления доступа
   - Выберите, показывать ли ваш сайт в поисковых системах

4. **Нажмите кнопку "Установить WordPress"**

5. **Войдите в административную панель** с созданными учетными данными

После этих шагов ваш WordPress будет готов к использованию, но для оптимальной работы рекомендуется выполнить дополнительную настройку с помощью специальных скриптов.

### Оптимизация производительности WordPress

Для улучшения производительности, безопасности и удобства работы с WordPress, мы подготовили специальный скрипт оптимизации:

1. **Подключитесь к серверу** через SSH или откройте терминал, если вы работаете локально

2. **Перейдите в директорию проекта**:
   ```bash
   cd /home/пользователь/cloud-local-n8n-flowise
   ```
   Замените "пользователь" на имя вашего пользователя.

3. **Запустите скрипт оптимизации**:
   ```bash
   sudo ./setup-files/wp-optimize.sh
   ```

4. **Дождитесь завершения установки**. Скрипт выполнит следующие действия:
   - Установит и активирует плагин W3 Total Cache для кеширования страниц и ускорения загрузки
   - Установит и активирует WP-Optimize для очистки базы данных от мусора
   - Установит и активирует Smush для оптимизации изображений
   - Установит и активирует Autoptimize для оптимизации CSS и JavaScript файлов
   - Установит дополнительные полезные плагины: Classic Editor, Wordfence Security, UpdraftPlus
   - Настроит оптимальные параметры WordPress в файле конфигурации

5. **После завершения работы скрипта**, перейдите в административную панель WordPress и выполните первоначальную настройку установленных плагинов:

   - **W3 Total Cache**: Перейдите в "Производительность" → "Общие настройки" и нажмите "Сохранить все настройки"
   - **WP-Optimize**: Перейдите в "WP-Optimize" → "Оптимизация базы данных" и запустите оптимизацию
   - **Wordfence Security**: Перейдите в "Wordfence" → "Настройки" и включите базовое сканирование

### Настройка регулярного резервного копирования WordPress

Для защиты ваших данных WordPress рекомендуется настроить регулярное резервное копирование:

1. **Ручное создание резервной копии**:
   ```bash
   sudo ./setup-files/wp-backup.sh
   ```
   Эта команда создаст полную резервную копию файлов WordPress и базы данных.

2. **Проверка созданной резервной копии**:
   ```bash
   ls -la /opt/backups/wordpress/
   ```
   Вы увидите два файла с текущей датой:
   - `wp_db_ДАТА-ВРЕМЯ.sql` - дамп базы данных
   - `wp_files_ДАТА-ВРЕМЯ.tar.gz` - архив файлов WordPress

3. **Настройка автоматического резервного копирования**:
   
   a. Откройте редактор cron:
   ```bash
   sudo crontab -e
   ```
   
   b. При первом запуске выберите предпочитаемый редактор (например, nano - опция 1)
   
   c. Добавьте в конец файла строку для ежедневного резервного копирования в 4:00 утра:
   ```
   0 4 * * * /home/пользователь/cloud-local-n8n-flowise/setup-files/wp-backup.sh
   ```
   Замените "пользователь" на имя вашего пользователя.
   
   d. Сохраните изменения:
      - В nano: нажмите Ctrl+O, затем Enter, затем Ctrl+X
      - В vim: нажмите Esc, затем :wq и Enter

4. **Проверка настройки cron**:
   ```bash
   sudo crontab -l
   ```
   Вы должны увидеть добавленную строку с заданием.

### Восстановление WordPress из резервной копии

Если вам нужно восстановить WordPress из резервной копии:

1. **Найдите доступные резервные копии**:
   ```bash
   ls -la /opt/backups/wordpress/
   ```

2. **Восстановление базы данных**:
   ```bash
   # Остановите WordPress перед восстановлением
   sudo docker compose -f /opt/wordpress-docker-compose.yaml --env-file /opt/.env stop wordpress
   
   # Восстановите базу данных (замените ИМЯ_ФАЙЛА на актуальное)
   sudo docker exec -i wordpress_db sh -c 'mysql -u${WP_DB_USER} -p${WP_DB_PASSWORD} ${WP_DB_NAME}' < /opt/backups/wordpress/ИМЯ_ФАЙЛА.sql
   
   # Запустите WordPress снова
   sudo docker compose -f /opt/wordpress-docker-compose.yaml --env-file /opt/.env start wordpress
   ```

3. **Восстановление файлов** (при необходимости):
   ```bash
   # Остановите WordPress перед восстановлением
   sudo docker compose -f /opt/wordpress-docker-compose.yaml --env-file /opt/.env stop wordpress
   
   # Извлеките файлы (замените ИМЯ_ФАЙЛА на актуальное)
   sudo docker run --rm -v wordpress_data:/var/www/html -v /opt/backups/wordpress:/backups alpine sh -c "rm -rf /var/www/html/* && tar -xzf /backups/ИМЯ_ФАЙЛА.tar.gz -C /"
   
   # Запустите WordPress снова
   sudo docker compose -f /opt/wordpress-docker-compose.yaml --env-file /opt/.env start wordpress
   ```

### Устранение распространенных проблем с WordPress

#### WordPress не запускается или недоступен

1. **Проверьте статус контейнеров**:
   ```bash
   sudo docker ps | grep wordpress
   ```

2. **Если контейнеры не запущены**, запустите их:
   ```bash
   sudo docker compose -f /opt/wordpress-docker-compose.yaml --env-file /opt/.env up -d
   ```

3. **Проверьте логи на наличие ошибок**:
   ```bash
   sudo docker logs wordpress
   sudo docker logs wordpress_db
   ```

#### Ошибка соединения с базой данных

1. **Проверьте, запущен ли контейнер базы данных**:
   ```bash
   sudo docker ps | grep wordpress_db
   ```

2. **Проверьте логи базы данных**:
   ```bash
   sudo docker logs wordpress_db
   ```

3. **Проверьте параметры подключения** в файле `/opt/.env` (должны присутствовать переменные `WP_DB_USER`, `WP_DB_PASSWORD`, `WP_DB_NAME`)

#### Проблемы с производительностью

1. **Запустите скрипт оптимизации**, если вы еще не сделали это:
   ```bash
   sudo ./setup-files/wp-optimize.sh
   ```

2. **Проверьте использование ресурсов**:
   ```bash
   sudo docker stats wordpress wordpress_db
   ```

3. **Рассмотрите возможность увеличения ресурсов** для контейнеров WordPress в файле `/opt/wordpress-docker-compose.yaml`

## Резервное копирование

Для создания резервных копий всех данных:

1. Запустите скрипт резервного копирования:
   ```bash
   sudo ./setup-files/10-backup-data.sh
   ```

2. Резервные копии будут сохранены в директории `/opt/backups/` в виде `.tar.gz` архивов с датой и временем.

3. Рекомендуется регулярно копировать эти резервные копии в надежное хранилище.

## Восстановление из резервных копий

1. Остановите сервис, данные которого нужно восстановить, например:
   ```bash
   sudo docker compose -f /opt/n8n-docker-compose.yaml stop n8n
   ```

2. Используйте временный контейнер для восстановления данных:
   ```bash
   sudo docker run --rm \
       -v n8n_data:/restore_dest \
       -v /opt/backups:/backups \
       alpine \
       tar xzf /backups/n8n_data_YYYYMMDD_HHMMSS.tar.gz -C /restore_dest
   ```

3. Перезапустите сервис:
   ```bash
   sudo docker compose -f /opt/n8n-docker-compose.yaml start n8n
   ```

## Структура проекта

- `setup.sh` - основной скрипт установки
- `setup-files/` - скрипты для отдельных этапов установки:
  - `01-update-system.sh` - обновление системы
  - `02-install-docker.sh` - установка Docker
  - `03-create-volumes.sh` - создание Docker-томов
  - `03b-setup-directories.sh` - настройка директорий
  - `04-generate-secrets.sh` - генерация секретных ключей
  - `05-create-templates.sh` - создание файлов конфигурации
  - `06-setup-firewall.sh` - настройка брандмауэра
  - `07-start-services.sh` - запуск сервисов
  - `check_disk_space.sh` - проверка свободного места
  - `10-backup-data.sh` - создание резервных копий
- Файлы шаблонов `*.template` для создания конфигураций Docker Compose и Caddy

## Безопасность

- Все сервисы доступны только по HTTPS с автоматически обновляемыми сертификатами Let's Encrypt
- Для всех сервисов генерируются случайные надежные пароли
- API Qdrant защищен API-ключом
- API Crawl4AI защищен JWT-аутентификацией
- Все тома Docker настроены для сохранения данных между перезапусками

## Устранение неполадок

### Проблемы с Caddy
Если Caddy не запускается или не удается получить сертификаты:
```bash
sudo docker logs caddy
```

### Диагностика всего стека
Запустите диагностический скрипт:
```bash
./setup-diag.sh
```

### Очистка неиспользуемых ресурсов Docker
Если заканчивается место на диске:
```bash
sudo docker system prune -a
```

## Лицензия

Данный проект распространяется под лицензией MIT.

## Контакты

При возникновении вопросов или проблем, пожалуйста, создайте issue в этом репозитории.
