# Автоматическая установка n8n, Flowise, Qdrant и других сервисов

Этот проект представляет собой набор скриптов для автоматизированной установки и настройки стека сервисов для работы с AI и автоматизацией рабочих процессов. Все сервисы развертываются в Docker-контейнерах и доступны через безопасные HTTPS-соединения благодаря Caddy.

## Включенные сервисы

- **n8n** - платформа автоматизации рабочих процессов с низкокодовым интерфейсом
  - Настроена для использования PostgreSQL для постоянного хранения данных
  - Включает Redis для организации очередей и кеширования
- **Flowise** - интерфейс для создания LLM-приложений и чат-цепочек
- **Qdrant** - векторная база данных для хранения и поиска эмбеддингов
  - Защищен API-ключом для безопасного доступа
- **Waha** - WhatsApp HTTP API для интеграции с WhatsApp через веб-интерфейс
  - Поддерживает отправку и получение сообщений через REST API
  - Обеспечивает удобную интеграцию с мессенджером WhatsApp
- **Crawl4AI** - веб-сервис для сбора данных и их обработки
- **Mem0** - интеллектуальный слой памяти для AI-ассистентов
  - Запоминает пользовательские предпочтения и контекст взаимодействия
  - Интегрируется с n8n и Flowise для создания персонализированных AI-решений
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

### Mem0
[Mem0](https://github.com/DarthSadist/mem0) ("мем-зеро") - это интеллектуальный слой памяти для AI-ассистентов, улучшающий персонализацию и контекстное взаимодействие:
- Многоуровневая память для сохранения состояния пользователя, сессии и агента
- Интеллектуальный поиск и извлечение релевантных воспоминаний на основе контекста
- Адаптивная персонализация ответов на основе предыдущих взаимодействий
- Использует существующие сервисы PostgreSQL и Qdrant для хранения данных
- Предоставляет REST API для легкой интеграции с n8n и Flowise
- Поддерживает различные LLM-модели, включая OpenAI, Anthropic и другие
- Обеспечивает безопасность доступа через API-ключи
- Предоставляет SDK для Python и JavaScript для удобной разработки
- Идеально подходит для создания персонализированных чат-ботов, виртуальных ассистентов и клиентской поддержки

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

### Waha
[Waha](https://waha.devlike.pro/) - это HTTP API для WhatsApp, позволяющий легко интегрировать WhatsApp-функциональность в любые приложения через RESTful API:
- Возможность отправлять и получать сообщения WhatsApp через HTTP-запросы
- Поддержка разных типов сообщений: текст, изображения, документы, аудио, видео, контакты
- Создание и управление группами WhatsApp
- Мониторинг статуса доставки сообщений
- Встроенная панель управления для отслеживания сессий и статусов
- Интеграция с n8n для построения полноценных чат-ботов
- Управление несколькими WhatsApp-номерами из одного интерфейса
- Поддержка webhook для мгновенного получения уведомлений о событиях
- Простая аутентификация через QR-код стандартного WhatsApp Web
- Возможность создания сложных сценариев обработки сообщений
- [Документация по API](https://waha.devlike.pro/docs/api-reference/overview/)

### Redis
[Redis](https://redis.io/docs/) - это высокопроизводительное хранилище данных в памяти, используемое как база данных, кэш и брокер сообщений:

- Хранение данных в ОЗУ для молниеносного доступа к информации
- Интеграция с n8n для обработки очередей и кеширования результатов выполнения рабочих процессов
- Поддержка различных структур данных: строки, хеши, списки, множества, упорядоченные множества
- Возможность эффективной организации очередей задач и управления распределенными блокировками
- Хранение сессий и временных данных между запусками рабочих процессов

#### Роль Redis в стеке сервисов

1. **Кеширование для n8n**:
   - Хранение промежуточных результатов выполнения рабочих процессов
   - Кеширование часто запрашиваемых данных для снижения нагрузки на внешние API
   - Хранение состояния выполнения длительных операций

2. **Управление очередями**:
   - Организация очередей выполнения для асинхронных рабочих процессов
   - Распределение нагрузки между исполнителями при масштабировании n8n
   - Предотвращение перегрузки системы при пиковой нагрузке

3. **Межсервисное взаимодействие**:
   - Обмен данными между n8n и другими сервисами стека
   - Быстрая передача сообщений между компонентами системы
   - Синхронизация состояний разных сервисов

#### Основные команды для работы с Redis

```bash
# Подключение к Redis из командной строки
sudo docker exec -it redis redis-cli

# Основные команды для диагностики
PING                  # Проверка соединения (должен вернуть PONG)
INFO                  # Общая информация о Redis-сервере
INFO memory           # Информация об использовании памяти
INFO clients          # Информация о подключенных клиентах
INFO stats            # Статистика использования

# Просмотр и работа с данными
KEYS *                # Получить список всех ключей (не рекомендуется в production)
SCAN 0                # Безопасный способ итерации по ключам
GET ключ              # Получить значение ключа
SET ключ значение     # Установить значение ключа
DEL ключ              # Удалить ключ
TTL ключ              # Проверить время жизни ключа (в секундах)
EXPIRE ключ 3600      # Установить время жизни ключа (3600 секунд)
```

#### Мониторинг и обслуживание Redis

1. **Мониторинг в Netdata**:
   - В панели Netdata перейдите в раздел "Applications" → "Redis"
   - Ключевые метрики: использование памяти, количество операций в секунду, хиты/промахи кеша
   - Настройте оповещения для критичных порогов (например, использование >80% выделенной памяти)

2. **Очистка кеша при необходимости**:
   ```bash
   # Подключение к Redis
   sudo docker exec -it redis redis-cli
   
   # Очистка всех данных (аккуратно в production!)
   FLUSHALL
   
   # Очистка данных только в текущей БД
   FLUSHDB
   
   # Очистка данных по определенному паттерну
   # Например, удалить все ключи с префиксом 'cache:'
   eval "return redis.call('del', unpack(redis.call('keys', ARGV[1])))" 0 cache:*
   ```

3. **Проверка логов Redis**:
   ```bash
   sudo docker logs redis
   ```

#### Настройка и оптимизация Redis

В текущей конфигурации Redis настроен оптимально для большинства сценариев использования. Однако при необходимости вы можете изменить настройки, отредактировав файл `/opt/redis.conf` или переменные окружения в `/opt/.env`:

```bash
# Пример настройки максимального объема памяти и политики вытеснения
# Добавьте эти строки в redis.conf или соответствующие переменные в .env
maxmemory 256mb
maxmemory-policy allkeys-lru   # Вытеснять наименее использовавшиеся ключи
```

#### Типичные сценарии использования Redis в n8n

1. **Кеширование данных API**:
   ```javascript
   // Пример кода для узла Function в n8n
   async function getDataWithCaching() {
     const cacheKey = 'cache:data:' + $input.item.id;
     
     // Попытка получить данные из кеша Redis
     const cachedData = await $redis.get(cacheKey);
     if (cachedData) {
       return JSON.parse(cachedData);
     }
     
     // Если данных нет в кеше, выполняем API-запрос
     const response = await $http.request({
       url: 'https://api.example.com/data/' + $input.item.id,
       method: 'GET'
     });
     
     // Сохраняем результат в кеш на 1 час
     await $redis.set(cacheKey, JSON.stringify(response.data));
     await $redis.expire(cacheKey, 3600);
     
     return response.data;
   }
   
   return await getDataWithCaching();
   ```

2. **Распределенные блокировки для предотвращения одновременного запуска**:
   ```javascript
   // Пример кода для предотвращения одновременного запуска рабочего процесса
   async function executeWithLock() {
     const lockKey = 'lock:process:daily-report';
     const lockValue = Date.now().toString();
     const lockTTL = 600; // 10 минут
     
     // Пытаемся получить блокировку
     const acquired = await $redis.set(lockKey, lockValue, 'NX', 'EX', lockTTL);
     
     if (!acquired) {
       return { success: false, message: 'Процесс уже выполняется' };
     }
     
     try {
       // Выполняем основную логику рабочего процесса
       // ...
       
       return { success: true, message: 'Процесс успешно выполнен' };
     } finally {
       // Освобождаем блокировку только если мы ее владельцы
       const currentValue = await $redis.get(lockKey);
       if (currentValue === lockValue) {
         await $redis.del(lockKey);
       }
     }
   }
   
   return await executeWithLock();
   ```

3. **Очередь заданий для распределения нагрузки**:
   ```javascript
   // В рабочем процессе-продюсере (создающем задачи)
   async function enqueueTask() {
     const task = {
       id: uuid(), // Уникальный идентификатор задачи
       type: 'data-processing',
       data: $input.item.json,
       created: Date.now()
     };
     
     // Добавляем задачу в очередь Redis
     await $redis.rpush('queue:data-processing', JSON.stringify(task));
     
     return { success: true, taskId: task.id };
   }
   
   // В рабочем процессе-потребителе (выполняющем задачи)
   async function processTaskFromQueue() {
     // Извлекаем задачу из очереди (блокирующая операция с таймаутом 5 секунд)
     const taskData = await $redis.blpop('queue:data-processing', 5);
     
     if (!taskData) {
       return { success: true, message: 'Нет задач в очереди' };
     }
     
     const task = JSON.parse(taskData[1]);
     
     try {
       // Выполняем обработку задачи
       // ...
       
       // Отмечаем задачу как выполненную
       await $redis.hset('tasks:completed', task.id, JSON.stringify({
         status: 'completed',
         completedAt: Date.now()
       }));
       
       return { success: true, taskId: task.id };
     } catch (error) {
       // В случае ошибки возвращаем задачу в очередь
       await $redis.rpush('queue:data-processing', JSON.stringify(task));
       return { success: false, error: error.message };
     }
   }
   ```

Вы также можете интегрировать Redis с Flowise и другими сервисами стека для создания высокопроизводительных и отказоустойчивых решений. Redis особенно полезен для кеширования векторных запросов к Qdrant и результатов обработки данных в AI-приложениях.

### Детальные примеры использования Redis в стеке

#### Пример 1: Мониторинг состояния сервисов с помощью n8n и Redis

Если вы хотите создать систему мониторинга для вашего стека сервисов, вы можете использовать Redis в качестве хранилища данных о состоянии и уведомлений:

```javascript
// Создайте рабочий процесс в n8n с триггером по расписанию (Schedule Trigger):
// - Добавьте ноду HTTP Request для проверки каждого сервиса
// - Затем добавьте Function ноду для обработки результатов:

// Пример кода для Function ноды:
async function monitorServices() {
  // Получение статуса от предыдущего узла HTTP Request
  const currentStatus = $input.item.json;
  const serviceName = currentStatus.service;
  const isUp = currentStatus.status === 'online';
  const timestamp = new Date().toISOString();
  
  // Получаем предыдущий статус из Redis
  const previousStateKey = `service:${serviceName}:status`;
  const previousState = await $redis.get(previousStateKey);
  
  // Сохраняем текущий статус в Redis
  await $redis.set(previousStateKey, isUp ? 'up' : 'down');
  
  // Сохраняем историю статусов в списке Redis (храним последние 100 записей)
  const historyKey = `service:${serviceName}:history`;
  await $redis.lpush(historyKey, JSON.stringify({
    timestamp,
    status: isUp ? 'up' : 'down',
    responseTime: currentStatus.responseTime || 0
  }));
  await $redis.ltrim(historyKey, 0, 99);  // Сохраняем только последние 100 записей
  
  // Обнаружение изменения статуса (для уведомлений)
  let statusChanged = false;
  if (previousState && (previousState === 'up') !== isUp) {
    statusChanged = true;
    
    // Добавляем событие в очередь уведомлений
    await $redis.rpush('notifications:queue', JSON.stringify({
      type: 'service_status_change',
      service: serviceName,
      status: isUp ? 'up' : 'down',
      previousStatus: previousState,
      timestamp
    }));
  }
  
  return {
    service: serviceName,
    status: isUp ? 'up' : 'down',
    statusChanged,
    lastChecked: timestamp
  };
}

return await monitorServices();
```

В этом примере Redis используется для:

1. Хранения текущего статуса сервисов
2. Сохранения истории статусов для анализа
3. Создания очереди уведомлений

Чтобы обрабатывать уведомления из очереди, создайте другой рабочий процесс, который будет периодически проверять очередь и отправлять уведомления по email или в мессенджеры.

#### Пример 2: Кеширование векторных запросов Qdrant в Flowise

При работе с Qdrant для векторного поиска можно использовать Redis для кеширования результатов семантического поиска. Это уменьшает нагрузку на векторную базу данных и ускоряет получение результатов для повторяющихся запросов:

```javascript
// Пример кода для JavaScript-узла в Flowise для кеширования векторных запросов

const axios = require('axios');
const crypto = require('crypto');
const Redis = require('ioredis');

// В n8n и Flowise клиент Redis уже доступен через встроенный объект $redis
// При использовании в отдельном скрипте:
const redis = new Redis({
  host: 'redis',  // Имя сервиса Redis в Docker-сети
  port: 6379
});

// Функция для семантического поиска с кешированием
async function semanticSearchWithCache(query, collectionName, limit = 5) {
  // Создаем хеш запроса для уникального ключа кеша
  const queryHash = crypto.createHash('md5').update(query + collectionName + limit).digest('hex');
  const cacheKey = `qdrant:search:${queryHash}`;
  
  // Проверяем наличие результатов в кеше
  const cachedResults = await redis.get(cacheKey);
  if (cachedResults) {
    console.log('Cache hit for query:', query);
    return JSON.parse(cachedResults);
  }
  
  // Если в кеше нет, выполняем запрос к Qdrant
  try {
    console.log('Cache miss for query:', query);
    
    // Первый шаг: получаем вектор эмбеддинга для запроса
    const embeddingResponse = await axios.post('https://api.openai.com/v1/embeddings', {
      input: query,
      model: 'text-embedding-3-small',
    }, {
      headers: {
        'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
    });
    
    const embedding = embeddingResponse.data.data[0].embedding;
    
    // Второй шаг: запрос к Qdrant для поиска схожих векторов
    const searchResponse = await axios.post(`https://qdrant.ваш-домен.com/collections/${collectionName}/points/search`, {
      vector: embedding,
      limit: limit,
      with_payload: true,
    }, {
      headers: {
        'Content-Type': 'application/json',
        'api-key': process.env.QDRANT_API_KEY,
      },
    });
    
    const results = searchResponse.data.result;
    
    // Сохраняем результаты в кеше на 30 минут
    await redis.set(cacheKey, JSON.stringify(results), 'EX', 1800);
    
    return results;
  } catch (error) {
    console.error('Error during semantic search:', error);
    throw error;
  }
}

// Пример использования функции
async function main() {
  const userQuery = inputs.question || "What are the benefits of vector databases?";
  const collection = inputs.collection || "knowledge_base";
  
  try {
    const searchResults = await semanticSearchWithCache(userQuery, collection);
    
    // Форматируем и возвращаем результаты
    return {
      results: searchResults.map(result => ({
        content: result.payload.text,
        metadata: result.payload.metadata,
        score: result.score,
      })),
      query: userQuery,
      source: `Qdrant: ${collection}`
    };
  } catch (error) {
    return { error: error.message };
  }
}

return await main();
```

Этот код демонстрирует следующие важные моменты использования Redis с Qdrant:

1. **Хеширование запросов**: Создание уникальных ключей на основе содержимого запроса
2. **Снижение нагрузки на API**: Экономия на запросах к модели эмбеддингов и Qdrant API
3. **Временное хранение данных**: Установка TTL (время жизни) для кешированных результатов

Этот подход особенно эффективен в сценариях, где пользователи часто задают похожие вопросы или ищут схожую информацию, что позволяет значительно снизить латентность и стоимость API-запросов.

#### Пример 3: Распределенная координация задач в n8n

Если вы запускаете несколько экземпляров n8n для масштабирования или высокой доступности, Redis может использоваться для координации задач между узлами:

```javascript
// Код для рабочего процесса распределения задач

async function processDataBatch() {
  // Уникальный ID для этого узла n8n 
  // В n8n можно получить его из переменных окружения
  const workerId = process.env.N8N_HOST || 'worker1';
  
  // Взять задачу из очереди (не блокирующий вызов)
  // Используем rpop для извлечения задачи с конца очереди (FIFO)
  const task = await $redis.rpop('tasks:pending');
  if (!task) {
    return { status: 'no_tasks' };
  }
  
  try {
    const taskData = JSON.parse(task);
    
    // Отметить задачу как в процессе обработки с указанием узла
    await $redis.hset('tasks:processing', taskData.id, JSON.stringify({
      worker: workerId,
      startTime: Date.now(),
      data: taskData
    }));
    
    // Обработка задачи (здесь ваша специфическая логика)
    const result = await processTask(taskData);
    
    // Отметить задачу как завершенную
    await $redis.hdel('tasks:processing', taskData.id);
    await $redis.hset('tasks:completed', taskData.id, JSON.stringify({
      worker: workerId,
      completionTime: Date.now(),
      result: result
    }));
    
    return { status: 'completed', taskId: taskData.id, result };
  } catch (error) {
    // В случае ошибки вернуть задачу в очередь
    // Используем lpush для возврата задачи в начало очереди в случае ошибки
    if (task) {
      await $redis.lpush('tasks:pending', task);
    }
    return { status: 'error', error: error.message };
  }
}

// Дополнительный код для периодической проверки зависших задач:

async function checkStaleTasks() {
  const now = Date.now();
  const staleTimeout = 10 * 60 * 1000; // 10 минут в миллисекундах
  
  // Получить все задачи в обработке
  const processingTasks = await $redis.hgetall('tasks:processing');
  
  let recoveredCount = 0;
  for (const [taskId, taskDataStr] of Object.entries(processingTasks)) {
    const taskData = JSON.parse(taskDataStr);
    
    // Если задача висит слишком долго, вернуть её в очередь
    if (now - taskData.startTime > staleTimeout) {
      await $redis.hdel('tasks:processing', taskId);
      await $redis.lpush('tasks:pending', JSON.stringify(taskData.data));
      recoveredCount++;
    }
  }
  
  return { recoveredTasks: recoveredCount };
}
```

Этот пример демонстрирует ключевые преимущества использования Redis для координации задач:

1. **Распределение нагрузки**: Задачи равномерно распределяются между рабочими узлами
2. **Отказоустойчивость**: Задачи автоматически возвращаются в очередь при сбоях
3. **Мониторинг прогресса**: Отслеживание статуса выполнения задач в реальном времени

Такой подход особенно полезен при масштабировании n8n, когда у вас есть много параллельных задач или вы хотите обеспечить высокую доступность и отказоустойчивость ваших процессов автоматизации.

### Crawl4AI
Crawl4AI - это веб-сервис, предназначенный для сбора данных из различных источников для AI-приложений. В текущей конфигурации он представлен как базовый API-эндпоинт, который может использоваться как отправная точка для интеграций:

- Простой API-эндпоинт с информацией о статусе сервиса
- Защита доступа с помощью JWT-аутентификации
- Интеграция с общей сетью Docker для взаимодействия с другими сервисами
- Возможность расширения функциональности через n8n и Flowise
- Легковесная конфигурация с минимальным потреблением ресурсов

### Практическое применение Crawl4AI в текущей конфигурации

Несмотря на минимальную реализацию, Crawl4AI может быть эффективно использован в различных сценариях:

#### 1. Мониторинг состояния стека в n8n

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

#### 2. Использование как базового API в Flowise

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

#### 3. Создание агрегатора данных с использованием n8n

Используйте n8n для сбора данных, а Crawl4AI как точку интеграции:

```bash
# Пример команды для запуска рабочего процесса n8n через CLI:
n8n execute --workflow "Web Scraper" --destinationUrl "https://crawl4ai.ваш-домен.com/" --authToken "${CRAWL4AI_JWT_SECRET}"
```

#### 4. Расширение через монтирование собственного кода

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

#### 5. Работа с внешними источниками данных

Ниже приведены примеры использования Crawl4AI с n8n и Flowise для работы с внешними источниками данных:

**a) Сбор данных с новостных сайтов (n8n)**

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

**b) Мониторинг RSS-каналов (n8n)**

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

**c) Интеграция с API внешних сервисов (Flowise)**

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

**d) Сбор данных с GitHub и интеграция с Qdrant**

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

#### Подробное руководство по использованию Adminer

##### Доступ и вход в Adminer

1. **Доступ к веб-интерфейсу**:
   - Откройте браузер и перейдите по адресу:
   ```
   https://adminer.ваш-домен.com
   ```

2. **Экран входа**:
   - На экране входа укажите следующие параметры:
     - **Система**: Выберите тип базы данных (PostgreSQL для n8n, MySQL/MariaDB для WordPress)
     - **Сервер**: Укажите имя сервера (например, `postgres` для n8n или `mariadb` для WordPress)
     - **Имя пользователя**: Укажите имя пользователя базы данных (`n8n` для n8n или значение `WP_DB_USER` для WordPress)
     - **Пароль**: Введите пароль из файла `/opt/.env`
     - **База данных**: Оставьте пустым для входа или укажите конкретное имя базы данных (`n8n` или `wordpress`)

3. **Для входа в базу данных PostgreSQL (n8n)**:
   ```
   Система: PostgreSQL
   Сервер: postgres
   Имя пользователя: n8n
   Пароль: [значение из /opt/.env]
   База данных: n8n
   ```

4. **Для входа в базу данных MariaDB (WordPress)**:
   ```
   Система: MySQL
   Сервер: mariadb или wordpress_db (в зависимости от конфигурации)
   Имя пользователя: [значение WP_DB_USER из /opt/.env]
   Пароль: [значение WP_DB_PASSWORD из /opt/.env]
   База данных: [значение WP_DB_NAME из /opt/.env]
   ```

5. **Как узнать свои данные для входа**:
   ```bash
   # Для PostgreSQL (n8n)
   grep -E "POSTGRES_USER|POSTGRES_PASSWORD|POSTGRES_DB" /opt/.env
   
   # Для WordPress
   grep -E "WP_DB_USER|WP_DB_PASSWORD|WP_DB_NAME" /opt/.env
   ```

##### Навигация по интерфейсу Adminer

После успешного входа вы увидите интерфейс Adminer со следующими основными элементами:

1. **Главное меню**:
   - **База данных**: Отображает имя текущей базы данных
   - **SQL-запрос**: Переход к редактору SQL
   - **Выход**: Завершение сессии
   - **Импорт**: Загрузка SQL-дампа в базу данных
   - **Экспорт**: Создание резервной копии базы данных

2. **Список таблиц**:
   - Слева отображается список всех таблиц в текущей базе данных
   - Щелчок по имени таблицы открывает её структуру и данные
   - Рядом с каждой таблицей отображается количество записей

3. **Кнопка создания таблицы**:
   - Находится внизу списка таблиц и позволяет создать новую таблицу

##### Основные операции с таблицами

1. **Просмотр данных таблицы**:
   - Щелкните по имени таблицы в списке слева
   - Нажмите на вкладку "Данные" или "Выбрать данные" для просмотра записей
   - Вы можете использовать фильтры и сортировку для удобства просмотра, нажав на заголовки столбцов

2. **Редактирование данных**:
   - После просмотра данных нажмите на иконку карандаша рядом с записью для её редактирования
   - Для удаления записи нажмите на иконку крестика (X)
   - Для добавления новой записи нажмите "Новая запись" внизу таблицы

3. **Работа со структурой таблицы**:
   - Нажмите на вкладку "Структура" после выбора таблицы
   - Вы можете добавлять, изменять или удалять поля (столбцы)
   - Для изменения поля нажмите на его имя в списке
   - Для добавления нового поля нажмите "Добавить поле" внизу списка полей

##### Выполнение SQL-запросов

1. **Доступ к редактору SQL**:
   - Нажмите на ссылку "SQL-запрос" в верхнем меню
   - В открывшемся текстовом поле вы можете ввести любой SQL-запрос

2. **Примеры полезных SQL-запросов для n8n (база данных PostgreSQL)**:

   - **Просмотр всех рабочих процессов**:
     ```sql
     SELECT id, name, active, created, updated 
     FROM workflow_entity 
     ORDER BY updated DESC;
     ```

   - **Просмотр активных выполнений**:
     ```sql
     SELECT id, finished, mode, retryOf, startedAt, stoppedAt, workflowId
     FROM execution_entity
     WHERE finished = false;
     ```

   - **Просмотр последних 10 выполнений**:
     ```sql
     SELECT id, finished, mode, startedAt, stoppedAt, workflowId, 
            (CASE WHEN finished THEN 'completed' ELSE 'running' END) as status
     FROM execution_entity
     ORDER BY startedAt DESC
     LIMIT 10;
     ```

3. **Примеры SQL-запросов для WordPress (MariaDB)**:

   - **Список всех страниц и записей**:
     ```sql
     SELECT ID, post_title, post_status, post_type, post_date 
     FROM wp_posts 
     WHERE post_type IN ('post', 'page') 
     ORDER BY post_date DESC;
     ```
     
   - **Просмотр всех пользователей**:
     ```sql
     SELECT ID, user_login, user_email, user_registered, user_status 
     FROM wp_users;
     ```

   - **Просмотр активных плагинов**:
     ```sql
     SELECT option_value 
     FROM wp_options 
     WHERE option_name = 'active_plugins';
     ```
     Примечание: результат будет в сериализованном PHP-формате

##### Экспорт и импорт данных

1. **Экспорт базы данных**:
   - Нажмите на ссылку "Экспорт" в главном меню
   - Выберите тип экспорта (обычно SQL)
   - Укажите, что экспортировать: всю базу данных или выбранные таблицы
   - Нажмите "Экспорт" для загрузки файла с дампом
   - Обратите внимание: для больших баз данных экспорт может занять значительное время

2. **Импорт данных**:
   - Нажмите на ссылку "Импорт" в главном меню
   - Выберите файл для загрузки (обычно .sql)
   - Нажмите "Импорт" для выполнения SQL-скрипта

3. **Экспорт только отдельной таблицы**:
   - Откройте нужную таблицу
   - Нажмите на вкладку "Экспорт"
   - Выберите формат и настройки
   - Нажмите "Экспорт" для сохранения данных таблицы

##### Полезные советы по работе с Adminer

1. **Безопасность**:
   - Не оставляйте сессию Adminer открытой без присмотра
   - Всегда завершайте сессию, нажимая "Выход" после завершения работы
   - Не выполняйте непроверенные SQL-запросы на продакшен-базе (особенно UPDATE, DELETE и ALTER TABLE)

2. **Выполнение запросов**:
   - Для выполнения сложных запросов сначала протестируйте их с ограничением LIMIT
   - Всегда делайте резервные копии перед выполнением DELETE или UPDATE запросов

3. **Производительность**:
   - Избегайте запросов SELECT * без ограничений на больших таблицах
   - Для работы с большими таблицами используйте фильтры и ограничения LIMIT

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

[Netdata](https://learn.netdata.cloud/docs/) - мощная система мониторинга производительности в реальном времени, предоставляющая детальную визуализацию ресурсов вашего сервера и контейнеров:

- Отслеживает тысячи метрик системы, приложений и контейнеров с секундной гранулярностью
- Предоставляет интерактивные дашборды с графиками производительности в реальном времени
- Автоматически определяет аномалии и потенциальные проблемы
- Имеет крайне низкие накладные расходы на мониторинг (менее 1% CPU)
- Не требует сложной настройки — работает "из коробки"

#### Руководство по использованию Netdata

##### Доступ к интерфейсу Netdata

Веб-интерфейс Netdata доступен по адресу:
```
https://netdata.ваш-домен.com
```

Для входа не требуется аутентификация. Если вы хотите ограничить доступ, рекомендуется настроить базовую аутентификацию через Caddy.

##### Основы навигации по интерфейсу

1. **Главная панель (Dashboard)**
   - После входа вы увидите основную панель с ключевыми метриками в реальном времени
   - В верхней части экрана находится меню с разделами и временная шкала
   - Графики автоматически обновляются каждую секунду

2. **Структура данных**
   - Метрики организованы в секции и подсекции
   - Слева расположено навигационное меню для быстрого перехода к различным категориям метрик

3. **Элементы управления графиками**
   - Наведите курсор на график для получения точных значений в конкретный момент времени
   - Используйте колесо мыши для масштабирования
   - Щелкните и перетащите для выделения конкретного временного интервала
   - Кнопка "Reset" возвращает масштаб к значениям по умолчанию

##### Мониторинг ключевых ресурсов

**Система**
- **CPU**: Отслеживание загрузки процессора всей системы и по ядрам
  - Обратите внимание на длительные периоды высокой загрузки (>80%)
  - Проверьте метрики iowait - высокие значения указывают на проблемы с диском

- **Память**: Использование RAM и swap
  - Контролируйте доступную память - низкие значения могут привести к деградации производительности
  - Если используется swap при наличии свободной RAM, проверьте настройки swappiness

- **Диск**: I/O операции, использование места и производительность
  - Следите за свободным местом на диске - критический порог <10%
  - Высокая загрузка диска может указывать на необходимость оптимизации приложений

- **Сеть**: Входящий/исходящий трафик, состояние соединений
  - Анализируйте пики трафика и корреляцию с нагрузкой на систему
  - Проверяйте количество установленных соединений

**Docker-контейнеры**

Netdata автоматически отслеживает все контейнеры в вашем стеке:

1. **Общий мониторинг контейнеров**
   - Перейдите в раздел "Containers" или "cgroups" в левом меню навигации для просмотра общей статистики
   - Сравнивайте использование ресурсов между контейнерами

2. **Мониторинг отдельных сервисов**
   - **n8n**: Отслеживайте использование CPU и RAM
     - Потребление ресурсов увеличивается при выполнении сложных рабочих процессов
     - Рекомендуемое использование CPU: `<60%` в среднем

   - **PostgreSQL**: Следите за метриками базы данных
     - Ключевые показатели: количество соединений, операции чтения/записи
     - При большом количестве медленных запросов рассмотрите возможность оптимизации

   - **Flowise**: Наблюдайте за поведением при выполнении AI-задач
     - Использование RAM может значительно возрастать при обработке больших документов
     - Потребление CPU увеличивается при параллельном выполнении нескольких задач

   - **Qdrant**: Контролируйте производительность векторной базы данных
     - Высокая загрузка CPU указывает на интенсивные векторные вычисления
     - Рост использования RAM связан с увеличением размера индекса

   - **WordPress**: Отслеживайте производительность CMS
     - Важны метрики PHP-FPM и MariaDB
     - Пики загрузки могут указывать на проблемы с плагинами или темой

##### Настройка оповещений

Netdata имеет встроенную систему оповещений:

1. **Просмотр активных оповещений**
   - Нажмите на колокольчик в правом верхнем углу для просмотра текущих предупреждений
   - Цветовая кодировка указывает на уровень критичности

2. **Настройка порогов оповещений**
   - Для изменения порогов нужно отредактировать файлы в директории `/etc/netdata/health.d/`
   - Настройки уведомлений задаются в файле `/etc/netdata/health_alarm_notify.conf`

3. **Настройка уведомлений по email**
   ```bash
   sudo docker exec -it netdata bash
   
   # В контейнере создайте/отредактируйте файл
   nano /etc/netdata/health_alarm_notify.conf
   
   # Добавьте следующие строки:
   SEND_EMAIL="YES"
   DEFAULT_RECIPIENT_EMAIL="your-email@example.com"
   
   # Сохраните файл: Ctrl+O, Enter, Ctrl+X
   ```

##### Расширенные функции

1. **Анализ производительности**
   - Используйте функцию "Metrics Correlations" для выявления взаимосвязей между метриками
   - Найдите корреляции при возникновении проблем для выявления первопричины

2. **Экспорт данных**
   - Экспортируйте данные для дальнейшего анализа, нажав на иконку загрузки на графике
   - Поддерживаются форматы CSV, JSON и другие

3. **Интеграция с n8n**
   - Создайте рабочий процесс в n8n для мониторинга критических метрик (добавьте узел HTTP Request и Function):
     ```javascript
     // Пример кода для узла Function в n8n
     async function checkNetdataMetrics() {
       const response = await $http.request({
         url: 'https://netdata.ваш-домен.com/api/v1/data?chart=system.cpu&format=json&points=1',
         method: 'GET'
       });
       
       const cpuUsage = response.data.data[0][1];
       
       if (cpuUsage > 80) {
         return {
           alert: true,
           message: `Высокая загрузка CPU: ${cpuUsage}%`,
           timestamp: new Date().toISOString()
         };
       }
       
       return { alert: false, cpuUsage };
     }
     
     return await checkNetdataMetrics();
     ```

##### Устранение неполадок

1. **Если графики не обновляются**
   - Перезапустите контейнер Netdata:
     ```bash
     sudo docker compose -f /opt/netdata-docker-compose.yaml --env-file /opt/.env restart
     ```
   - Проверьте логи для выявления проблем:
     ```bash
     sudo docker logs netdata
     ```

2. **Высокая нагрузка самого Netdata**
   - Уменьшите частоту обновления, изменив параметр `update_every` в файле `/etc/netdata/netdata.conf` (например, значение 5 будет обновлять данные каждые 5 секунд вместо 1)
   - Отключите ненужные коллекторы данных для снижения нагрузки

3. **Очистка исторических данных**
   - По умолчанию Netdata хранит данные в памяти
   - Для очистки базы данных перезапустите контейнер

##### Рекомендации по мониторингу

1. **Ежедневные проверки**
   - Проверяйте общую загрузку системы (CPU, RAM, диск)
   - Отслеживайте активные предупреждения и тенденции использования ресурсов

2. **Еженедельный анализ**
   - Анализируйте производительность отдельных контейнеров
   - Ищите паттерны и аномалии в использовании ресурсов

3. **Действия при высокой нагрузке**
   - Определите процессы, потребляющие больше всего ресурсов
   - Рассмотрите возможность масштабирования ресурсов или оптимизации приложений

Netdata предоставляет исчерпывающую информацию о вашей системе, позволяя оперативно выявлять и устранять проблемы производительности.

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
- **Waha**: https://waha.ваш-домен/dashboard/

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
sudo docker compose -f /opt/netdata-docker-compose.yaml --env-file /opt/.env restart

# Перезапуск Waha
sudo docker compose -f /opt/waha-docker-compose.yaml --env-file /opt/.env restart
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
sudo docker compose -f /opt/wordpress-docker-compose.yaml --env-file /opt/.env down
sudo docker compose -f /opt/watchtower-docker-compose.yaml down
sudo docker compose -f /opt/netdata-docker-compose.yaml --env-file /opt/.env down
sudo docker compose -f /opt/waha-docker-compose.yaml --env-file /opt/.env down
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

# Просмотр логов Waha
sudo docker logs waha

# Просмотр логов Waha в реальном времени
sudo docker logs -f waha
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
   0 4 * * * /home/${USER}/cloud-local-n8n-flowise/setup-files/wp-backup.sh
   ```
   
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
   
   # Восстановите базу данных (замените ИМЯ_ФАЙЛА на актуальное имя резервной копии)
   sudo docker exec -i wordpress_db sh -c 'mysql -u${WP_DB_USER} -p${WP_DB_PASSWORD} ${WP_DB_NAME}' < /opt/backups/wordpress/ИМЯ_ФАЙЛА.sql
   
   # Запустите WordPress снова
   sudo docker compose -f /opt/wordpress-docker-compose.yaml --env-file /opt/.env start wordpress
   ```

3. **Восстановление файлов** (при необходимости):
   ```bash
   # Остановите WordPress перед восстановлением
   sudo docker compose -f /opt/wordpress-docker-compose.yaml --env-file /opt/.env stop wordpress
   
   # Извлеките файлы (замените ИМЯ_ФАЙЛА на актуальное имя архива)
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

## Примеры интеграции с Mem0

### Интеграция Mem0 с n8n

Mem0 можно легко интегрировать с n8n для создания персонализированных AI-рабочих процессов с памятью:

#### Пример 1: Чат-бот с памятью пользовательских предпочтений

Создадим рабочий процесс в n8n, который использует Mem0 для запоминания предпочтений пользователя:

1. **Настройка триггера**:
   - Добавьте ноду "Webhook" для получения сообщений от пользователя

2. **Извлечение данных пользователя**:
   - Добавьте ноду "Function" для извлечения user_id и текста сообщения

3. **Поиск в памяти Mem0**:
   - Добавьте ноду "HTTP Request" со следующими настройками:
     ```
     URL: http://mem0:3456/api/memories/search
     Method: POST
     Headers: 
       Content-Type: application/json
       Authorization: Bearer {{$env.MEM0_API_KEY}}
     Body:
     {
       "query": "{{$node["Function"].json["message"]}}",
       "user_id": "{{$node["Function"].json["user_id"]}}",
       "limit": 5
     }
     ```

4. **Генерация ответа с учетом памяти**:
   - Добавьте ноду "OpenAI" для генерации ответа:
     ```
     Model: gpt-4o-mini
     Prompt: Ответь на вопрос пользователя, используя следующие воспоминания: {{$json["results"].map(item => item.memory).join("\n")}}

     Вопрос пользователя: {{$node["Function"].json["message"]}}
     ```

5. **Сохранение новой памяти**:
   - Добавьте еще одну ноду "HTTP Request" для сохранения новой памяти:
     ```
     URL: http://mem0:3456/api/memories
     Method: POST
     Headers: 
       Content-Type: application/json
       Authorization: Bearer {{$env.MEM0_API_KEY}}
     Body:
     {
       "user_id": "{{$node["Function"].json["user_id"]}}",
       "messages": [
         {"role": "user", "content": "{{$node["Function"].json["message"]}}"},
         {"role": "assistant", "content": "{{$node["OpenAI"].json["response"]}}"}
       ]
     }
     ```

6. **Отправка ответа пользователю**:
   - Добавьте ноду для отправки ответа пользователю (например, "Respond to Webhook" или другой канал связи)

#### Пример 2: Анализ трендов в пользовательских запросах

Создадим рабочий процесс в n8n, который анализирует тренды в запросах пользователей с помощью Mem0:

```javascript
// Нода Function для анализа трендов в памяти Mem0
async function analyzeTrends() {
  // Получаем все запросы за последние 7 дней
  const lastWeekDate = new Date();
  lastWeekDate.setDate(lastWeekDate.getDate() - 7);
  
  const response = await $http.request({
    method: 'GET',
    url: 'http://mem0:3456/api/memories',
    headers: {
      'Authorization': `Bearer ${$env.MEM0_API_KEY}`
    },
    qs: {
      'from_date': lastWeekDate.toISOString(),
      'limit': 1000
    }
  });
  
  // Анализируем тренды в запросах
  const memories = response.data.results;
  const topics = {};
  
  memories.forEach(memory => {
    if (memory.role === 'user') {
      // Простой анализ ключевых слов
      const content = memory.content.toLowerCase();
      ['product', 'price', 'support', 'feature', 'bug'].forEach(topic => {
        if (content.includes(topic)) {
          topics[topic] = (topics[topic] || 0) + 1;
        }
      });
    }
  });
  
  // Сортировка трендов по популярности
  const sortedTopics = Object.entries(topics)
    .sort((a, b) => b[1] - a[1])
    .map(([topic, count]) => ({ topic, count }));
  
  return { trends: sortedTopics };
}

return await analyzeTrends();
```

### Интеграция Mem0 с Flowise

Mem0 можно интегрировать с Flowise для создания персонализированных чат-ботов и AI-агентов с памятью:

#### Пример: Создание чат-бота с памятью в Flowise

В Flowise можно интегрировать Mem0 с помощью компонента "API Tool":

1. **Создание компонента API Tool для Mem0**:
   - Добавьте компонент "API Tool"
   - Настройте его для работы с Mem0 API:
     ```
     Name: MemorySearch
     Method: POST
     URL: http://mem0:3456/api/memories/search
     Headers: 
       Content-Type: application/json
       Authorization: Bearer {{$secrets.MEM0_API_KEY}}
     ```

2. **Создание второго API Tool для сохранения памяти**:
   - Добавьте еще один компонент "API Tool"
   - Настройте его для сохранения памяти:
     ```
     Name: MemorySave
     Method: POST
     URL: http://mem0:3456/api/memories
     Headers: 
       Content-Type: application/json
       Authorization: Bearer {{$secrets.MEM0_API_KEY}}
     ```

3. **Создание цепочки чат-бота**:
   - Добавьте компонент "Chat Input"
   - Добавьте компонент "Function", чтобы подготовить запрос к Mem0:
     ```javascript
     const userId = inputs.chatInput.chatId || "default_user";
     const query = inputs.chatInput.text;
     
     return {
       query: query,
       user_id: userId,
       limit: 5
     };
     ```
   - Свяжите этот компонент с "MemorySearch" API Tool
   
   - Добавьте компонент "LLM Chain", чтобы сгенерировать ответ с учетом памяти:
     ```
     Системный промпт: Ты персональный ассистент. Используй следующие воспоминания о пользователе для персонализации ответа: {{memories}}
     
     Пользовательский промпт: {{query}}
     ```
     Где `{{memories}}` - это результаты из MemorySearch, а `{{query}}` - текст запроса пользователя.

   - Добавьте еще один компонент "Function" для подготовки данных для сохранения памяти:
     ```javascript
     return {
       user_id: inputs.chatInput.chatId || "default_user",
       messages: [
         {role: "user", content: inputs.chatInput.text},
         {role: "assistant", content: inputs.llmChain}
       ]
     };
     ```
   - Свяжите этот компонент с "MemorySave" API Tool
   
   - Добавьте компонент "Chat Output" и свяжите его с выходом LLM Chain

4. **Настройка секретов**:
   - В настройках Flowise добавьте секрет `MEM0_API_KEY` с вашим ключом API Mem0

Таким образом, вы создадите в Flowise чат-бота, который использует Mem0 для хранения и извлечения памяти о пользователях.

## Примеры интеграции с Waha

### Интеграция Waha с n8n

WhatsApp HTTP API (Waha) можно легко интегрировать с n8n для создания автоматизированных чат-ботов и рабочих процессов:

#### Пример 1: Простой WhatsApp-бот с n8n

```javascript
// Пример рабочего процесса n8n для создания простого WhatsApp-бота

// 1. Создайте вебхук-триггер для получения уведомлений от Waha
// 2. Добавьте узел Function для обработки сообщений:

// Код для узла Function:
const message = $input.item.json.body.message; // Получаем сообщение от пользователя
const senderNumber = $input.item.json.body.from; // Номер отправителя

let response = "";

// Простая логика обработки команд
if (message.text && message.text.toLowerCase() === 'привет') {
  response = 'Привет! Я бот, созданный с помощью n8n и Waha API.';
} else if (message.text && message.text.toLowerCase() === 'помощь') {
  response = 'Доступные команды:\n- привет\n- помощь\n- время';
} else if (message.text && message.text.toLowerCase() === 'время') {
  const now = new Date();
  response = `Текущее время: ${now.toLocaleString()}`;
} else {
  response = 'Не понимаю эту команду. Напишите "помощь" для списка команд.';
}

// Возвращаем данные для следующего узла
return {
  response: response,
  senderNumber: senderNumber
};

// 3. Затем добавьте узел HTTP Request для отправки ответа:
// URL: https://waha.${DOMAIN_NAME}/api/v1/messages/send
// Method: POST
// Headers: {"Content-Type": "application/json"}
// Body: JSON
// {
//   "chatId": "{{$json["senderNumber"]}}",
//   "text": "{{$json["response"]}}"
// }
```

#### Пример 2: Интеграция Waha с Flowise и n8n

Вы можете использовать Flowise для создания AI-бота, и затем интегрировать его с WhatsApp через Waha и n8n:

1. Создайте чатбот в Flowise и опубликуйте API для него
2. В n8n создайте рабочий процесс со следующими шагами:
   - Webhook триггер для получения сообщений от Waha
   - HTTP Request для отправки запроса к Flowise API
   - HTTP Request для отправки ответа через Waha в WhatsApp

```javascript
// Код для адаптации данных для Flowise API
const message = $input.item.json.body.message;
const senderNumber = $input.item.json.body.from;
const chatId = $input.item.json.body.chatId;

// Сохраняем информацию о отправителе для ответа
const senderInfo = {
  senderNumber: senderNumber,
  chatId: chatId,
  text: message.text || ''
};

return senderInfo;

// Затем настройте HTTP Request к Flowise API:
// URL: https://flowise.${DOMAIN_NAME}/api/v1/prediction/{YOUR_FLOWISE_CHATFLOW_ID}
// Method: POST
// Headers: {"Content-Type": "application/json"}
// Body: JSON
// {
//   "question": "{{$json["text"]}}",
//   "sessionId": "{{$json["chatId"]}}"
// }

// И наконец, отправьте ответ через Waha API
```

### Регистрация Webhook в Waha

Для получения уведомлений о событиях в WhatsApp необходимо зарегистрировать webhook в Waha:

```bash
# Зарегистрируйте webhook для получения всех сообщений
curl -X POST "https://waha.${DOMAIN_NAME}/api/v1/webhooks" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://n8n.${DOMAIN_NAME}/webhook/waha",
    "events": ["message", "message.ack"]
  }'
```

Для управления webhook используйте следующие команды:

```bash
# Получить список всех webhook
curl "https://waha.${DOMAIN_NAME}/api/v1/webhooks"

# Удалить webhook по ID
curl -X DELETE "https://waha.${DOMAIN_NAME}/api/v1/webhooks/{webhookId}"
```

### Управление сервисом Mem0

Для управления сервисом Mem0 используйте следующие команды:

```bash
# Запуск Mem0
sudo docker compose -f /opt/mem0-docker-compose.yaml --env-file /opt/.env up -d

# Остановка Mem0
sudo docker compose -f /opt/mem0-docker-compose.yaml --env-file /opt/.env stop

# Перезапуск Mem0
sudo docker compose -f /opt/mem0-docker-compose.yaml --env-file /opt/.env restart

# Просмотр логов Mem0
sudo docker logs mem0

# Просмотр логов в режиме реального времени
sudo docker logs -f mem0
```

#### Настройка OpenAI API Key

Для работы Mem0 требуется действующий ключ OpenAI API. Чтобы его настроить:

1. Отредактируйте файл `/opt/.env`:
   ```bash
   sudo nano /opt/.env
   ```

2. Найдите строку `OPENAI_API_KEY="sk-your-openai-api-key"` и замените ее на ваш реальный ключ OpenAI API.

3. Сохраните файл и перезапустите сервис Mem0:
   ```bash
   sudo docker compose -f /opt/mem0-docker-compose.yaml --env-file /opt/.env restart
   ```

#### Резервное копирование данных Mem0

Данные Mem0 хранятся в томе Docker `mem0_data`. Для резервного копирования используйте:

```bash
# Создание резервной копии
sudo docker run --rm -v mem0_data:/data -v $(pwd):/backup alpine tar -czf /backup/mem0_backup_$(date +%Y%m%d).tar.gz /data

# Восстановление из резервной копии
sudo docker stop mem0
sudo docker run --rm -v mem0_data:/data -v $(pwd):/backup alpine sh -c "rm -rf /data/* && tar -xzf /backup/mem0_backup_YYYYMMDD.tar.gz -C /"
sudo docker start mem0
```

#### Очистка старых данных

Для очистки старых данных из Mem0 можно использовать API запросы:

```bash
# Удаление старых записей (старше 30 дней)
curl -X DELETE "http://localhost:3456/api/memories" \
  -H "Authorization: Bearer $MEM0_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"older_than_days": 30}'
```

#### Устранение неполадок

Если Mem0 не работает корректно, проверьте:

1. **Правильность ключа OpenAI API**:
   ```bash
   # Проверка ключа OpenAI API
   grep OPENAI_API_KEY /opt/.env
   ```

2. **Доступность сервиса**:
   ```bash
   # Проверка доступности API
   curl -I http://localhost:3456/api/health
   ```

3. **Логи для диагностики**:
   ```bash
   sudo docker logs mem0
   ```

### Управление сервисом Waha

Для управления сервисом Waha отдельно от других сервисов, используйте следующие команды:

```bash
# Запуск Waha
sudo docker compose -f /opt/waha-docker-compose.yaml --env-file /opt/.env up -d

# Остановка Waha
sudo docker compose -f /opt/waha-docker-compose.yaml --env-file /opt/.env stop

# Перезапуск Waha (особенно полезно при необходимости перегенерировать QR-код для авторизации)
sudo docker compose -f /opt/waha-docker-compose.yaml --env-file /opt/.env restart

# Просмотр логов Waha
sudo docker logs waha

# Просмотр логов в реальном времени (для отладки)
sudo docker logs -f waha
```

После перезапуска сервиса Waha необходимо повторно пройти авторизацию, отсканировав QR-код в панели управления по адресу https://waha.${DOMAIN_NAME}/dashboard/

## Устранение неполадок

### Проблемы с Caddy
Если Caddy не запускается или не удается получить сертификаты:
```bash
sudo docker logs caddy
```

### Проблемы с Waha
Если у вас возникли проблемы с Waha:

1. **Проверьте логи контейнера**:
```bash
sudo docker logs waha
```

2. **Перезапустите сервис для перегенерации QR-кода**:
```bash
sudo docker compose -f /opt/waha-docker-compose.yaml --env-file /opt/.env restart
```

3. **Проверьте сессии WhatsApp**:
   - Откройте панель управления Waha по адресу https://waha.${DOMAIN_NAME}/dashboard
   - Проверьте статус сессии и при необходимости отсканируйте QR-код заново

4. **Проверьте API запросом**:
```bash
curl "https://waha.${DOMAIN_NAME}/api/v1/sessions"
```

### Диагностика всего стека
Запустите диагностический скрипт:
```bash
./setup-files/setup-diag.sh
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
