# Подробное руководство по работе с сервисом Mem0

## Содержание

1. [Введение](#введение)
2. [Установка и настройка](#установка-и-настройка)
3. [Базовые концепции](#базовые-концепции)
4. [API Reference](#api-reference)
5. [Интеграция с n8n](#интеграция-с-n8n)
6. [Интеграция с Flowise](#интеграция-с-flowise)
7. [Примеры использования](#примеры-использования)
8. [Управление и обслуживание](#управление-и-обслуживание)
9. [Устранение неполадок](#устранение-неполадок)
10. [Часто задаваемые вопросы](#часто-задаваемые-вопросы)

## Введение

Mem0 ("мем-зеро") - это интеллектуальный слой памяти для AI-ассистентов, который позволяет создавать персонализированные взаимодействия с пользователями. Сервис запоминает контекст общения, предпочтения пользователей и важную информацию, что позволяет AI-решениям адаптироваться к индивидуальным потребностям.

### Для чего нужен Mem0

- **Персонализация взаимодействия**: Адаптация ответов AI на основе предыдущих взаимодействий
- **Долговременная память**: Сохранение контекста между сессиями
- **Улучшение пользовательского опыта**: Создание более естественных и последовательных диалогов
- **Снижение повторений**: Избавление от необходимости повторно предоставлять одну и ту же информацию

### Ключевые возможности

- Многоуровневая память (пользователь, сессия, агент)
- Интеллектуальный поиск релевантных воспоминаний
- Интеграция с популярными LLM-моделями
- REST API для легкой интеграции
- Использование векторных баз данных для эффективного поиска

## Установка и настройка

В этом разделе описаны процессы установки и настройки Mem0 в вашем стеке.

### Предварительные требования

Для работы Mem0 требуются следующие компоненты:

- Docker и Docker Compose
- PostgreSQL (уже настроен в вашем стеке)
- Qdrant (уже настроен в вашем стеке)
- Действующий ключ OpenAI API

### Процесс установки

Если вы используете скрипт `setup.sh` для установки всего стека, Mem0 будет установлен автоматически. Если вы хотите установить Mem0 вручную, выполните следующие шаги:

1. **Создание тома Docker**:
   ```bash
   docker volume create mem0_data
   ```

2. **Настройка переменных окружения**:
   Добавьте следующие переменные в файл `.env`:
   ```
   # --- Mem0 Settings ---
   MEM0_API_KEY="ваш_случайный_ключ"
   OPENAI_API_KEY="ваш_ключ_openai"
   MEM0_HOST="0.0.0.0"
   MEM0_PORT="3456"
   ```

3. **Создание файла Docker Compose**:
   Создайте файл `mem0-docker-compose.yaml` со следующим содержимым:
   ```yaml
   version: '3.8'
   services:
     mem0:
       image: node:18-alpine
       container_name: mem0
       restart: unless-stopped
       working_dir: /app
       command: >
         sh -c "apk add --no-cache git python3 py3-pip &&
                git clone https://github.com/DarthSadist/mem0.git . &&
                if [ -f requirements.txt ]; then
                  pip install -r requirements.txt;
                else
                  pip install mem0ai;
                fi &&
                npm install &&
                npm start || python -m mem0.server"
       environment:
         - MEM0_API_KEY=${MEM0_API_KEY}
         - OPENAI_API_KEY=${OPENAI_API_KEY}
         - DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
         - QDRANT_URL=http://qdrant:6333
         - QDRANT_API_KEY=${QDRANT_API_KEY}
         - MEM0_HOST=${MEM0_HOST}
         - MEM0_PORT=${MEM0_PORT}
       expose:
         - "3456"
       volumes:
         - mem0_data:/app/data
       networks:
         - app-network
       depends_on:
         - postgres
         - qdrant
   
   networks:
     app-network:
       external: true
   
   volumes:
     mem0_data:
       external: true
   ```

4. **Настройка Caddy**:
   Добавьте следующую конфигурацию в файл `Caddyfile`:
   ```
   # Mem0 - AI Memory Layer
   mem0.$DOMAIN_NAME {
       reverse_proxy mem0:3456
       header {
           # Добавление заголовков безопасности
           Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
           X-Content-Type-Options "nosniff"
           X-Frame-Options "SAMEORIGIN"
           Referrer-Policy "strict-origin-when-cross-origin"
       }
   }
   ```

5. **Запуск сервиса**:
   ```bash
   docker compose -f mem0-docker-compose.yaml --env-file .env up -d
   ```

### Настройка OpenAI API Key

Для работы Mem0 необходим действующий ключ OpenAI API. Чтобы его настроить:

1. Получите ключ API на сайте [OpenAI](https://platform.openai.com/api-keys)

2. Отредактируйте файл `.env`:
   ```bash
   sudo nano /opt/.env
   ```

3. Найдите строку `OPENAI_API_KEY="sk-your-openai-api-key"` и замените ее на ваш реальный ключ OpenAI API.

4. Сохраните файл и перезапустите сервис Mem0:
   ```bash
   sudo docker compose -f /opt/mem0-docker-compose.yaml --env-file /opt/.env restart
   ```

### Проверка установки

После установки проверьте, что сервис работает корректно:

1. **Проверка статуса контейнера**:
   ```bash
   docker ps | grep mem0
   ```
   Вы должны увидеть запущенный контейнер mem0.

2. **Проверка логов**:
   ```bash
   docker logs mem0
   ```
   В логах не должно быть ошибок.

3. **Проверка API**:
   ```bash
   curl -I http://localhost:3456/api/health
   ```
   Вы должны получить ответ `HTTP/1.1 200 OK`.

4. **Проверка доступа через Caddy**:
   ```bash
   curl -I https://mem0.yourdomain.com/api/health
   ```
   Замените `yourdomain.com` на ваш домен. Вы должны получить ответ `HTTP/2 200`.

Если все проверки прошли успешно, сервис Mem0 установлен и готов к использованию.

## Базовые концепции

В этом разделе описаны основные концепции и термины, используемые в Mem0.

### Структура памяти

Mem0 использует многоуровневую структуру памяти:

1. **Пользовательская память (User Memory)**: Долговременная память, связанная с конкретным пользователем. Сохраняется между сессиями и содержит информацию о предпочтениях, истории взаимодействий и важных фактах о пользователе.

2. **Сессионная память (Session Memory)**: Кратковременная память для текущего разговора или сессии. Автоматически очищается при завершении сессии.

3. **Агентская память (Agent Memory)**: Память, связанная с конкретным AI-агентом. Содержит информацию о возможностях, ограничениях и специфических знаниях агента.

### Типы воспоминаний

В Mem0 существуют следующие типы воспоминаний:

1. **Факты (Facts)**: Конкретная фактическая информация о пользователе или контексте.
   ```json
   {
     "content": "Пользователь предпочитает получать уведомления по email",
     "type": "fact"
   }
   ```

2. **Предпочтения (Preferences)**: Информация о предпочтениях пользователя.
   ```json
   {
     "content": "Пользователь предпочитает краткие ответы без технических деталей",
     "type": "preference"
   }
   ```

3. **Взаимодействия (Interactions)**: Записи о прошлых взаимодействиях с пользователем.
   ```json
   {
     "content": "Пользователь спрашивал о настройке API ключей 15 мая 2025",
     "type": "interaction"
   }
   ```

4. **Метаданные (Metadata)**: Дополнительная информация, которая может быть полезна для контекста.
   ```json
   {
     "content": "Последний вход в систему: 18 мая 2025",
     "type": "metadata"
   }
   ```

### Векторные эмбеддинги

Mem0 использует векторные эмбеддинги для эффективного поиска релевантных воспоминаний:

1. **Создание эмбеддингов**: Каждое воспоминание преобразуется в векторное представление с помощью моделей OpenAI.

2. **Семантический поиск**: При запросе релевантных воспоминаний система выполняет поиск по семантической близости, а не по точному совпадению ключевых слов.

3. **Ранжирование результатов**: Результаты поиска ранжируются по релевантности к текущему контексту.

### Жизненный цикл воспоминаний

1. **Создание**: Воспоминания создаются на основе взаимодействия с пользователем или явных запросов на сохранение информации.

2. **Хранение**: Воспоминания сохраняются в PostgreSQL (структурированные данные) и Qdrant (векторные эмбеддинги).

3. **Поиск**: При необходимости система ищет релевантные воспоминания на основе текущего контекста.

4. **Обновление**: Существующие воспоминания могут быть обновлены при получении новой информации.

5. **Удаление**: Воспоминания могут быть удалены по запросу пользователя или по истечении срока хранения.

### Ключевые параметры API

1. **user_id**: Уникальный идентификатор пользователя для персонализации памяти.

2. **session_id**: Идентификатор текущей сессии для группировки связанных взаимодействий.

3. **agent_id**: Идентификатор AI-агента, если используется несколько разных агентов.

4. **relevance_threshold**: Порог релевантности для фильтрации результатов поиска (0.0 - 1.0).

5. **limit**: Максимальное количество возвращаемых воспоминаний.

## API Reference

В этом разделе описаны основные конечные точки API Mem0. Для всех запросов требуется заголовок `Authorization: Bearer YOUR_MEM0_API_KEY`.

### Создание воспоминания

```
POST /api/memories
```

**Тело запроса:**
```json
{
  "user_id": "user123",
  "content": "Пользователь предпочитает получать уведомления по email",
  "type": "preference",
  "session_id": "session456",
  "agent_id": "assistant789",
  "metadata": {
    "source": "user_settings",
    "timestamp": "2025-05-18T10:30:00Z"
  }
}
```

**Ответ:**
```json
{
  "id": "mem_1234567890",
  "user_id": "user123",
  "content": "Пользователь предпочитает получать уведомления по email",
  "type": "preference",
  "created_at": "2025-05-18T10:30:05Z",
  "updated_at": "2025-05-18T10:30:05Z"
}
```

### Поиск релевантных воспоминаний

```
POST /api/memories/search
```

**Тело запроса:**
```json
{
  "user_id": "user123",
  "query": "Какие предпочтения по уведомлениям у пользователя?",
  "relevance_threshold": 0.7,
  "limit": 5,
  "types": ["preference", "fact"],
  "session_id": "session456",
  "agent_id": "assistant789"
}
```

**Ответ:**
```json
{
  "memories": [
    {
      "id": "mem_1234567890",
      "content": "Пользователь предпочитает получать уведомления по email",
      "type": "preference",
      "relevance_score": 0.92,
      "created_at": "2025-05-18T10:30:05Z"
    },
    {
      "id": "mem_0987654321",
      "content": "Пользователь не хочет получать push-уведомления",
      "type": "preference",
      "relevance_score": 0.85,
      "created_at": "2025-05-10T14:20:30Z"
    }
  ],
  "total": 2
}
```

### Получение воспоминания по ID

```
GET /api/memories/:id
```

**Параметры запроса:**
- `id`: Идентификатор воспоминания

**Ответ:**
```json
{
  "id": "mem_1234567890",
  "user_id": "user123",
  "content": "Пользователь предпочитает получать уведомления по email",
  "type": "preference",
  "created_at": "2025-05-18T10:30:05Z",
  "updated_at": "2025-05-18T10:30:05Z",
  "metadata": {
    "source": "user_settings",
    "timestamp": "2025-05-18T10:30:00Z"
  }
}
```

### Обновление воспоминания

```
PUT /api/memories/:id
```

**Параметры запроса:**
- `id`: Идентификатор воспоминания

**Тело запроса:**
```json
{
  "content": "Пользователь предпочитает получать уведомления по email и SMS",
  "metadata": {
    "source": "user_settings",
    "timestamp": "2025-05-19T15:45:00Z",
    "updated_by": "system"
  }
}
```

**Ответ:**
```json
{
  "id": "mem_1234567890",
  "user_id": "user123",
  "content": "Пользователь предпочитает получать уведомления по email и SMS",
  "type": "preference",
  "created_at": "2025-05-18T10:30:05Z",
  "updated_at": "2025-05-19T15:45:05Z",
  "metadata": {
    "source": "user_settings",
    "timestamp": "2025-05-19T15:45:00Z",
    "updated_by": "system"
  }
}
```

### Удаление воспоминания

```
DELETE /api/memories/:id
```

**Параметры запроса:**
- `id`: Идентификатор воспоминания

**Ответ:**
```json
{
  "success": true,
  "message": "Воспоминание успешно удалено"
}
```

### Получение всех воспоминаний пользователя

```
GET /api/memories/user/:user_id
```

**Параметры запроса:**
- `user_id`: Идентификатор пользователя
- `type` (опционально): Фильтр по типу воспоминания
- `limit` (опционально): Максимальное количество результатов
- `offset` (опционально): Смещение для пагинации

**Ответ:**
```json
{
  "memories": [
    {
      "id": "mem_1234567890",
      "content": "Пользователь предпочитает получать уведомления по email и SMS",
      "type": "preference",
      "created_at": "2025-05-18T10:30:05Z",
      "updated_at": "2025-05-19T15:45:05Z"
    },
    {
      "id": "mem_0987654321",
      "content": "Пользователь не хочет получать push-уведомления",
      "type": "preference",
      "created_at": "2025-05-10T14:20:30Z",
      "updated_at": "2025-05-10T14:20:30Z"
    }
  ],
  "total": 2,
  "limit": 10,
  "offset": 0
}
```

### Проверка статуса API

```
GET /api/health
```

**Ответ:**
```json
{
  "status": "ok",
  "version": "1.0.0",
  "timestamp": "2025-05-19T16:00:00Z"
}
```
## Интеграция с n8n

В этом разделе описаны способы интеграции Mem0 с платформой автоматизации n8n.

### Настройка HTTP запросов в n8n

Для взаимодействия с API Mem0 из n8n используйте ноду HTTP Request:

1. **Добавление ноды HTTP Request**:
   - В рабочем пространстве n8n добавьте новую ноду HTTP Request
   - Настройте метод (GET, POST, PUT, DELETE) в зависимости от требуемой операции

2. **Настройка аутентификации**:
   - В разделе "Authentication" выберите "Bearer Token"
   - В поле "Token" введите ваш API ключ Mem0 (переменная `MEM0_API_KEY` из файла `.env`)

3. **Настройка URL и параметров**:
   - URL: `https://mem0.yourdomain.com/api/memories` (для создания воспоминания)
   - Body (для POST/PUT запросов): JSON с параметрами воспоминания

### Пример рабочего процесса: Сохранение пользовательских предпочтений

Этот пример показывает, как сохранять предпочтения пользователя в Mem0 при их изменении:

1. **Триггер**: Webhook или Form Trigger для получения данных о предпочтениях пользователя

2. **Обработка данных**: Function ноду для подготовки данных
   ```javascript
   // Пример кода для Function ноды
   const userData = {
     user_id: $input.item.userId,
     content: `Пользователь предпочитает тему: ${$input.item.theme}`,
     type: "preference",
     metadata: {
       source: "user_settings",
       timestamp: new Date().toISOString()
     }
   };
   
   return {
     json: userData
   };
   ```

3. **Отправка в Mem0**: HTTP Request ноду с настройками:
   - Method: POST
   - URL: https://mem0.yourdomain.com/api/memories
   - Authentication: Bearer Token
   - Body: Expression: $json

4. **Обработка ответа**: Дополнительные действия на основе ответа API

### Пример рабочего процесса: Получение релевантных воспоминаний

Этот пример показывает, как получать релевантные воспоминания для персонализации ответов:

1. **Триггер**: Webhook с запросом пользователя

2. **Подготовка запроса поиска**: Function ноду для формирования запроса
   ```javascript
   // Пример кода для Function ноды
   const searchQuery = {
     user_id: $input.item.userId,
     query: $input.item.message,
     relevance_threshold: 0.7,
     limit: 5,
     types: ["preference", "fact"]
   };
   
   return {
     json: searchQuery
   };
   ```

3. **Поиск воспоминаний**: HTTP Request ноду с настройками:
   - Method: POST
   - URL: https://mem0.yourdomain.com/api/memories/search
   - Authentication: Bearer Token
   - Body: Expression: $json

4. **Использование результатов**: Включение найденных воспоминаний в ответ пользователю

### Использование воспоминаний для персонализации ответов

Пример интеграции с OpenAI для персонализации ответов на основе воспоминаний:

1. **Получение запроса пользователя**: Webhook или Chat Trigger

2. **Поиск релевантных воспоминаний**: HTTP Request к Mem0 API

3. **Формирование запроса к OpenAI**: Function ноду для создания промпта
   ```javascript
   // Пример кода для Function ноды
   const memories = $node["HTTP Request"].json.memories;
   let memoryContext = "";
   
   if (memories && memories.length > 0) {
     memoryContext = "Информация о пользователе:\n";
     memories.forEach(mem => {
       memoryContext += `- ${mem.content}\n`;
     });
   }
   
   const prompt = `${memoryContext}
   
   Пользователь спрашивает: ${$input.item.message}
   
   Пожалуйста, дай персонализированный ответ с учетом информации о пользователе.`;
   
   return {
     json: {
       prompt: prompt
     }
   };
   ```

4. **Запрос к OpenAI**: OpenAI ноду с настроенным API ключом

5. **Отправка ответа пользователю**: Respond to Webhook ноду

### Автоматическое сохранение контекста разговора

Пример рабочего процесса для автоматического сохранения важной информации из разговора:

1. **Получение сообщения**: Webhook или Chat Trigger

2. **Анализ сообщения**: OpenAI ноду для извлечения важной информации
   ```
   Проанализируй следующее сообщение пользователя и извлеки из него важную информацию, 
   которую стоит запомнить для будущих взаимодействий. Верни результат в формате JSON:
   {
     "should_remember": true/false,
     "content": "Извлеченная информация в виде факта",
     "type": "fact/preference/interaction"
   }
   
   Сообщение пользователя: {{$input.item.message}}
   ```

3. **Проверка необходимости сохранения**: IF ноду с условием `$json.should_remember === true`

4. **Сохранение в Mem0**: HTTP Request ноду для отправки извлеченной информации

### Советы по эффективной интеграции

1. **Использование переменных окружения**:
   - Храните API ключи и URL в переменных окружения n8n
   - Используйте Expression: `{{$env.MEM0_API_KEY}}` для доступа к ключу

2. **Обработка ошибок**:
   - Добавляйте ноды Error Trigger для обработки ошибок API
   - Логируйте неудачные запросы для отладки

3. **Оптимизация производительности**:
   - Устанавливайте разумные лимиты для количества возвращаемых воспоминаний
   - Кэшируйте часто используемые воспоминания с помощью n8n Storage
## Интеграция с Flowise

В этом разделе описаны способы интеграции Mem0 с платформой для создания AI-приложений Flowise.

### Настройка API-интеграции в Flowise

Для взаимодействия с API Mem0 из Flowise используйте ноду API:

1. **Добавление ноды API**:
   - В рабочем пространстве Flowise добавьте новую ноду API
   - Настройте метод (GET, POST, PUT, DELETE) в зависимости от требуемой операции

2. **Настройка аутентификации**:
   - В разделе "Authentication" выберите "Bearer Token"
   - В поле "Token" введите ваш API ключ Mem0 (переменная `MEM0_API_KEY` из файла `.env`)

3. **Настройка URL и параметров**:
   - URL: `https://mem0.yourdomain.com/api/memories` (для создания воспоминания)
   - Body (для POST/PUT запросов): JSON с параметрами воспоминания

### Интеграция с LangChain в Flowise

Flowise позволяет использовать компоненты LangChain, что дает возможность создать более гибкую интеграцию с Mem0:

1. **Настройка LangChain Memory**:
   - Добавьте ноду "LangChain Memory"
   - Настройте пользовательский обработчик памяти, который будет взаимодействовать с Mem0

2. **Пример кода для интеграции с LangChain**:
   ```javascript
   const axios = require('axios');

   class Mem0Memory {
     constructor(config) {
       this.apiKey = config.apiKey;
       this.baseUrl = config.baseUrl;
       this.userId = config.userId;
       this.sessionId = config.sessionId;
     }

     async saveContext(inputValues, outputValues) {
       try {
         const content = `Пользователь спросил: ${inputValues.input}. Ответ: ${outputValues.output}`;
         await axios.post(
           `${this.baseUrl}/api/memories`,
           {
             user_id: this.userId,
             session_id: this.sessionId,
             content: content,
             type: "interaction",
             metadata: {
               timestamp: new Date().toISOString()
             }
           },
           {
             headers: {
               'Authorization': `Bearer ${this.apiKey}`,
               'Content-Type': 'application/json'
             }
           }
         );
       } catch (error) {
         console.error('Error saving to Mem0:', error);
       }
     }

     async loadMemoryVariables() {
       try {
         const response = await axios.post(
           `${this.baseUrl}/api/memories/search`,
           {
             user_id: this.userId,
             session_id: this.sessionId,
             relevance_threshold: 0.7,
             limit: 5
           },
           {
             headers: {
               'Authorization': `Bearer ${this.apiKey}`,
               'Content-Type': 'application/json'
             }
           }
         );
         
         let memoryString = "";
         if (response.data.memories && response.data.memories.length > 0) {
           memoryString = "Предыдущий контекст:\n";
           response.data.memories.forEach(mem => {
             memoryString += `- ${mem.content}\n`;
           });
         }
         
         return { memory: memoryString };
       } catch (error) {
         console.error('Error loading from Mem0:', error);
         return { memory: "" };
       }
     }
   }

   // Использование в Flowise
   module.exports = { Mem0Memory };
   ```

### Пример рабочего процесса: Чат-бот с памятью

Этот пример показывает, как создать чат-бота с долговременной памятью с использованием Mem0:

1. **Настройка входных параметров**:
   - Добавьте ноду "Text Input" для получения сообщения пользователя
   - Добавьте ноду "User Information" для получения идентификатора пользователя

2. **Получение релевантных воспоминаний**:
   - Добавьте ноду "API" для запроса к Mem0
   - Настройте POST запрос к `/api/memories/search`
   - Настройте параметры запроса с использованием идентификатора пользователя

3. **Формирование контекста для LLM**:
   - Добавьте ноду "Code" для обработки результатов запроса
   ```javascript
   const memories = inputs.memories.memories || [];
   let context = "";
   
   if (memories.length > 0) {
     context = "Информация о пользователе из предыдущих взаимодействий:\n";
     memories.forEach(mem => {
       context += `- ${mem.content}\n`;
     });
   }
   
   return { context };
   ```

4. **Генерация ответа с использованием LLM**:
   - Добавьте ноду "ChatOpenAI" или другую модель
   - Настройте системный промпт с учетом контекста из памяти
   ```
   Ты - полезный ассистент. Используй следующую информацию о пользователе для персонализации ответа:
   
   {{context}}
   
   Отвечай кратко и по существу.
   ```

5. **Сохранение нового взаимодействия**:
   - Добавьте ноду "API" для сохранения взаимодействия в Mem0
   - Настройте POST запрос к `/api/memories`
   - Включите в тело запроса информацию о взаимодействии

### Использование Mem0 для персонализации генерации изображений

Пример интеграции с генераторами изображений, учитывающий предпочтения пользователя:

1. **Получение предпочтений пользователя**:
   - Запрос к Mem0 для получения предпочтений по стилю, цветам и т.д.

2. **Формирование промпта для генерации изображения**:
   ```javascript
   const userPreferences = inputs.memories.memories
     .filter(mem => mem.type === "preference" && mem.content.includes("изображение"))
     .map(mem => mem.content);
   
   let stylePreferences = "";
   if (userPreferences.length > 0) {
     stylePreferences = userPreferences.join(". ");
   } else {
     stylePreferences = "Нейтральный стиль";
   }
   
   const imagePrompt = `${inputs.basePrompt}, ${stylePreferences}`;
   
   return { imagePrompt };
   ```

3. **Генерация изображения**:
   - Использование ноды "Stable Diffusion" или "DALL-E" с персонализированным промптом

### Советы по эффективной интеграции

1. **Управление контекстом**:
   - Ограничивайте количество возвращаемых воспоминаний для предотвращения перегрузки контекста
   - Используйте высокий порог релевантности для получения только наиболее важных воспоминаний

2. **Обработка ошибок**:
   - Всегда добавляйте обработку ошибок для API-запросов
   - Предусматривайте запасные варианты в случае недоступности Mem0

3. **Оптимизация производительности**:
   - Кэшируйте результаты запросов к Mem0 для часто используемых данных
   - Используйте асинхронные запросы для улучшения отзывчивости интерфейса

4. **Безопасность**:
   - Храните API ключи в переменных окружения
   - Проверяйте и валидируйте данные перед сохранением в Mem0
## Примеры использования

В этом разделе представлены практические примеры использования Mem0 для различных сценариев.

### Персонализированный чат-бот

Создание чат-бота, который запоминает предпочтения и историю общения с пользователем:

1. **Сохранение информации о пользователе**:
   ```bash
   curl -X POST https://mem0.yourdomain.com/api/memories \
     -H "Authorization: Bearer YOUR_MEM0_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "user_id": "user123",
       "content": "Пользователь предпочитает получать технические детали в ответах",
       "type": "preference"
     }'
   ```

2. **Получение релевантных воспоминаний при новом сообщении**:
   ```bash
   curl -X POST https://mem0.yourdomain.com/api/memories/search \
     -H "Authorization: Bearer YOUR_MEM0_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "user_id": "user123",
       "query": "Как настроить Docker?",
       "relevance_threshold": 0.7,
       "limit": 5
     }'
   ```

3. **Использование воспоминаний для формирования ответа**:
   ```javascript
   // Пример кода для формирования промпта к LLM
   const prompt = `
   Информация о пользователе:
   ${memories.map(m => `- ${m.content}`).join('\n')}
   
   Вопрос пользователя: ${userMessage}
   
   Дай персонализированный ответ с учетом предпочтений пользователя.
   `;
   ```

### Система рекомендаций

Использование Mem0 для создания персонализированной системы рекомендаций:

1. **Сохранение предпочтений пользователя**:
   ```bash
   curl -X POST https://mem0.yourdomain.com/api/memories \
     -H "Authorization: Bearer YOUR_MEM0_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "user_id": "user123",
       "content": "Пользователь интересуется темами: искусственный интеллект, программирование, наука о данных",
       "type": "preference"
     }'
   ```

2. **Сохранение истории взаимодействий**:
   ```bash
   curl -X POST https://mem0.yourdomain.com/api/memories \
     -H "Authorization: Bearer YOUR_MEM0_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "user_id": "user123",
       "content": "Пользователь просмотрел статью 'Введение в нейронные сети'",
       "type": "interaction",
       "metadata": {
         "item_id": "article_12345",
         "category": "artificial_intelligence"
       }
     }'
   ```

3. **Получение рекомендаций на основе истории и предпочтений**:
   ```javascript
   // Пример кода для генерации рекомендаций
   const userMemories = await fetchMemoriesForUser("user123");
   const preferences = userMemories.filter(m => m.type === "preference");
   const interactions = userMemories.filter(m => m.type === "interaction");
   
   // Анализ предпочтений и истории
   const interests = extractInterests(preferences);
   const viewedItems = interactions.map(i => i.metadata.item_id);
   
   // Генерация рекомендаций
   const recommendations = await generateRecommendations(interests, viewedItems);
   ```

### Персонализированный обучающий курс

Адаптация обучающего контента под потребности и уровень знаний пользователя:

1. **Сохранение информации об уровне знаний**:
   ```bash
   curl -X POST https://mem0.yourdomain.com/api/memories \
     -H "Authorization: Bearer YOUR_MEM0_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "user_id": "student123",
       "content": "Пользователь имеет средний уровень знаний в программировании на Python",
       "type": "fact"
     }'
   ```

2. **Отслеживание прогресса**:
   ```bash
   curl -X POST https://mem0.yourdomain.com/api/memories \
     -H "Authorization: Bearer YOUR_MEM0_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "user_id": "student123",
       "content": "Пользователь успешно завершил модуль 'Основы функционального программирования'",
       "type": "interaction",
       "metadata": {
         "module_id": "python_functional",
         "completion_date": "2025-05-15T14:30:00Z",
         "score": 85
       }
     }'
   ```

3. **Адаптация контента на основе прогресса**:
   ```javascript
   // Пример кода для адаптации обучающего контента
   const studentMemories = await fetchMemoriesForUser("student123");
   const knowledgeLevel = assessKnowledgeLevel(studentMemories);
   const completedModules = extractCompletedModules(studentMemories);
   
   // Генерация персонализированного учебного плана
   const nextModules = recommendNextModules(knowledgeLevel, completedModules);
   const adaptedContent = adjustDifficulty(nextModules[0], knowledgeLevel);
   ```

### Виртуальный ассистент для команды

Создание ассистента, который помогает команде, запоминая контекст проекта:

1. **Сохранение информации о проекте**:
   ```bash
   curl -X POST https://mem0.yourdomain.com/api/memories \
     -H "Authorization: Bearer YOUR_MEM0_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "user_id": "team_project_x",
       "content": "Проект X использует стек технологий: React, Node.js, PostgreSQL",
       "type": "fact"
     }'
   ```

2. **Сохранение решений и обсуждений**:
   ```bash
   curl -X POST https://mem0.yourdomain.com/api/memories \
     -H "Authorization: Bearer YOUR_MEM0_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "user_id": "team_project_x",
       "content": "Команда решила использовать Redux для управления состоянием приложения",
       "type": "interaction",
       "metadata": {
         "meeting_date": "2025-05-10T10:00:00Z",
         "participants": ["user1", "user2", "user3"]
       }
     }'
   ```

3. **Получение контекста при обсуждении**:
   ```javascript
   // Пример кода для получения контекста проекта
   const projectMemories = await fetchMemoriesForUser("team_project_x");
   const techStack = extractTechStack(projectMemories);
   const pastDecisions = extractDecisions(projectMemories);
   
   // Формирование ответа с учетом контекста проекта
   const response = generateContextAwareResponse(userQuestion, techStack, pastDecisions);
   ```

### Интеграция с умным домом

Использование Mem0 для персонализации системы умного дома:

1. **Сохранение предпочтений по настройкам дома**:
   ```bash
   curl -X POST https://mem0.yourdomain.com/api/memories \
     -H "Authorization: Bearer YOUR_MEM0_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "user_id": "home_user1",
       "content": "Пользователь предпочитает температуру 22°C в гостиной вечером",
       "type": "preference"
     }'
   ```

2. **Отслеживание паттернов использования**:
   ```bash
   curl -X POST https://mem0.yourdomain.com/api/memories \
     -H "Authorization: Bearer YOUR_MEM0_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "user_id": "home_user1",
       "content": "Пользователь обычно включает свет в спальне в 22:30",
       "type": "pattern",
       "metadata": {
         "device": "bedroom_light",
         "action": "turn_on",
         "time": "22:30",
         "frequency": "daily"
       }
     }'
   ```

3. **Автоматизация на основе предпочтений**:
   ```javascript
   // Пример кода для автоматизации умного дома
   const userMemories = await fetchMemoriesForUser("home_user1");
   const timePatterns = extractTimePatterns(userMemories);
   const preferences = extractPreferences(userMemories);
   
   // Настройка автоматизаций
   scheduleAutomations(timePatterns);
   adjustSettings(preferences);
   ```
## Управление и обслуживание

В этом разделе описаны основные операции по управлению и обслуживанию сервиса Mem0.

### Мониторинг состояния

Для отслеживания состояния сервиса Mem0 используйте следующие команды:

1. **Проверка статуса контейнера**:
   ```bash
   docker ps | grep mem0
   ```
   Вы должны увидеть запущенный контейнер с именем `mem0`.

2. **Просмотр логов**:
   ```bash
   docker logs mem0
   ```
   Для непрерывного отслеживания логов добавьте флаг `-f`:
   ```bash
   docker logs -f mem0
   ```

3. **Проверка использования ресурсов**:
   ```bash
   docker stats mem0
   ```
   Эта команда покажет использование CPU, памяти и сети контейнером.

4. **Проверка доступности API**:
   ```bash
   curl -I https://mem0.yourdomain.com/api/health
   ```
   Ожидаемый ответ: `HTTP/2 200`

### Управление сервисом

Основные команды для управления сервисом Mem0:

1. **Запуск сервиса**:
   ```bash
   docker compose -f /opt/mem0-docker-compose.yaml --env-file /opt/.env up -d
   ```

2. **Остановка сервиса**:
   ```bash
   docker compose -f /opt/mem0-docker-compose.yaml down
   ```

3. **Перезапуск сервиса**:
   ```bash
   docker compose -f /opt/mem0-docker-compose.yaml --env-file /opt/.env restart
   ```

4. **Обновление сервиса**:
   ```bash
   # Остановка контейнера
   docker compose -f /opt/mem0-docker-compose.yaml down
   
   # Удаление образа для загрузки новой версии
   docker rmi node:18-alpine
   
   # Запуск сервиса (будет загружена новая версия)
   docker compose -f /opt/mem0-docker-compose.yaml --env-file /opt/.env up -d
   ```

### Резервное копирование данных

Регулярное резервное копирование данных Mem0 поможет предотвратить потерю важной информации:

1. **Резервное копирование тома Docker**:
   ```bash
   docker run --rm -v mem0_data:/data -v $(pwd):/backup alpine tar -czf /backup/mem0_backup_$(date +%Y%m%d).tar.gz /data
   ```
   Эта команда создаст архив с данными Mem0 в текущей директории с именем вида `mem0_backup_20250518.tar.gz`.

2. **Резервное копирование базы данных PostgreSQL**:
   ```bash
   docker exec postgres pg_dump -U postgres -d mem0 > mem0_db_backup_$(date +%Y%m%d).sql
   ```
   Эта команда создаст дамп базы данных Mem0 в текущей директории.

3. **Резервное копирование данных Qdrant**:
   ```bash
   docker run --rm -v qdrant_storage:/data -v $(pwd):/backup alpine tar -czf /backup/qdrant_backup_$(date +%Y%m%d).tar.gz /data
   ```
   Эта команда создаст архив с данными Qdrant в текущей директории.

4. **Автоматизация резервного копирования**:
   Создайте скрипт для автоматического резервного копирования и добавьте его в crontab:
   ```bash
   # /opt/backup_mem0.sh
   #!/bin/bash
   
   BACKUP_DIR="/opt/backups"
   DATE=$(date +%Y%m%d)
   
   # Создание директории для резервных копий
   mkdir -p $BACKUP_DIR
   
   # Резервное копирование тома Mem0
   docker run --rm -v mem0_data:/data -v $BACKUP_DIR:/backup alpine tar -czf /backup/mem0_backup_$DATE.tar.gz /data
   
   # Резервное копирование базы данных
   docker exec postgres pg_dump -U postgres -d mem0 > $BACKUP_DIR/mem0_db_backup_$DATE.sql
   
   # Удаление старых резервных копий (старше 30 дней)
   find $BACKUP_DIR -name "mem0_*" -type f -mtime +30 -delete
   ```
   
   Добавление в crontab для ежедневного запуска в 2:00:
   ```bash
   0 2 * * * /opt/backup_mem0.sh
   ```

### Восстановление из резервной копии

В случае необходимости восстановления данных из резервной копии:

1. **Восстановление тома Docker**:
   ```bash
   # Остановка сервиса
   docker compose -f /opt/mem0-docker-compose.yaml down
   
   # Восстановление данных
   docker run --rm -v mem0_data:/data -v $(pwd):/backup alpine sh -c "rm -rf /data/* && tar -xzf /backup/mem0_backup_20250518.tar.gz -C /"
   
   # Запуск сервиса
   docker compose -f /opt/mem0-docker-compose.yaml --env-file /opt/.env up -d
   ```

2. **Восстановление базы данных PostgreSQL**:
   ```bash
   cat mem0_db_backup_20250518.sql | docker exec -i postgres psql -U postgres -d mem0
   ```

### Очистка данных

Периодическая очистка устаревших данных поможет оптимизировать производительность:

1. **Очистка старых воспоминаний через API**:
   ```bash
   # Получение списка старых воспоминаний (пример: созданных более 6 месяцев назад)
   curl -X GET "https://mem0.yourdomain.com/api/memories/user/user123?created_before=2024-11-18T00:00:00Z" \
     -H "Authorization: Bearer YOUR_MEM0_API_KEY" > old_memories.json
   
   # Удаление старых воспоминаний
   cat old_memories.json | jq -r '.memories[].id' | while read id; do
     curl -X DELETE "https://mem0.yourdomain.com/api/memories/$id" \
       -H "Authorization: Bearer YOUR_MEM0_API_KEY"
   done
   ```

2. **Очистка базы данных PostgreSQL**:
   ```bash
   docker exec -i postgres psql -U postgres -d mem0 -c "DELETE FROM memories WHERE created_at < NOW() - INTERVAL '6 months';"
   ```

3. **Оптимизация базы данных**:
   ```bash
   docker exec -i postgres psql -U postgres -d mem0 -c "VACUUM FULL ANALYZE;"
   ```

### Обновление API ключей

Периодическое обновление API ключей повышает безопасность:

1. **Генерация нового API ключа**:
   ```bash
   NEW_API_KEY=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
   echo "Новый API ключ: $NEW_API_KEY"
   ```

2. **Обновление ключа в файле .env**:
   ```bash
   sudo sed -i "s/MEM0_API_KEY=.*/MEM0_API_KEY=$NEW_API_KEY/" /opt/.env
   ```

3. **Перезапуск сервиса для применения изменений**:
   ```bash
   docker compose -f /opt/mem0-docker-compose.yaml --env-file /opt/.env restart
   ```

4. **Обновление ключа в интеграциях**:
   Не забудьте обновить API ключ во всех интеграциях с n8n, Flowise и других сервисах, которые используют Mem0.

### Настройка производительности

Оптимизация производительности Mem0 для вашей нагрузки:

1. **Настройка лимитов ресурсов**:
   Отредактируйте файл `mem0-docker-compose.yaml` и добавьте ограничения ресурсов:
   ```yaml
   services:
     mem0:
       # ... существующая конфигурация ...
       deploy:
         resources:
           limits:
             cpus: '1'
             memory: 1G
           reservations:
             cpus: '0.25'
             memory: 512M
   ```

2. **Настройка параметров базы данных**:
   Оптимизация PostgreSQL для работы с Mem0:
   ```bash
   docker exec -i postgres psql -U postgres -d mem0 -c "
   ALTER SYSTEM SET shared_buffers = '256MB';
   ALTER SYSTEM SET work_mem = '16MB';
   ALTER SYSTEM SET maintenance_work_mem = '128MB';
   ALTER SYSTEM SET random_page_cost = 1.1;
   ALTER SYSTEM SET effective_cache_size = '512MB';
   "
   
   # Применение изменений
   docker exec -i postgres psql -U postgres -c "SELECT pg_reload_conf();"
   ```

3. **Индексирование базы данных**:
   ```bash
   docker exec -i postgres psql -U postgres -d mem0 -c "
   CREATE INDEX IF NOT EXISTS idx_memories_user_id ON memories(user_id);
   CREATE INDEX IF NOT EXISTS idx_memories_type ON memories(type);
   CREATE INDEX IF NOT EXISTS idx_memories_created_at ON memories(created_at);
   "
   ```

### Устранение неполадок

Распространенные проблемы и их решения:

1. **Сервис не запускается**:
   ```bash
   # Проверка логов
   docker logs mem0
   
   # Проверка переменных окружения
   docker compose -f /opt/mem0-docker-compose.yaml --env-file /opt/.env config
   
   # Проверка доступности зависимостей
   docker exec -i postgres psql -U postgres -c "\l" | grep mem0
   curl -I http://qdrant:6333/collections
   ```

2. **Ошибки подключения к API**:
   ```bash
   # Проверка сетевых настроек
   docker network inspect app-network
   
   # Проверка прослушиваемых портов
   docker exec mem0 netstat -tulpn | grep 3456
   
   # Проверка настроек Caddy
   docker exec caddy cat /etc/caddy/Caddyfile | grep mem0
   ```

3. **Проблемы с производительностью**:
   ```bash
   # Мониторинг использования ресурсов
   docker stats mem0 postgres qdrant
   
   # Проверка количества запросов
   docker exec -i postgres psql -U postgres -d mem0 -c "SELECT COUNT(*) FROM memories;"
   
   # Анализ медленных запросов
   docker exec -i postgres psql -U postgres -d mem0 -c "
   SELECT query, calls, total_time, mean_time
   FROM pg_stat_statements
   ORDER BY mean_time DESC
   LIMIT 10;
   "
   ```

4. **Проблемы с OpenAI API**:
   ```bash
   # Проверка доступности API OpenAI
   docker exec mem0 curl -I https://api.openai.com/v1/models
   
   # Проверка ключа API
   docker exec mem0 sh -c 'echo $OPENAI_API_KEY | wc -c'
   ```
## Устранение неполадок

В этом разделе описаны распространенные проблемы, которые могут возникнуть при работе с Mem0, и способы их решения.

### Проблемы при установке

1. **Ошибка при создании тома Docker**:
   
   **Проблема**: `Error response from daemon: create mem0_data: volume name is already in use`
   
   **Решение**:
   ```bash
   # Проверьте существующие тома
   docker volume ls | grep mem0_data
   
   # Если том существует, но не используется, удалите его
   docker volume rm mem0_data
   
   # Создайте том заново
   docker volume create mem0_data
   ```

2. **Ошибка при запуске контейнера**:
   
   **Проблема**: `Error response from daemon: Conflict. The container name "/mem0" is already in use`
   
   **Решение**:
   ```bash
   # Проверьте существующие контейнеры
   docker ps -a | grep mem0
   
   # Удалите существующий контейнер
   docker rm -f mem0
   
   # Запустите контейнер заново
   docker compose -f /opt/mem0-docker-compose.yaml --env-file /opt/.env up -d
   ```

3. **Ошибка при клонировании репозитория**:
   
   **Проблема**: `fatal: unable to access 'https://github.com/DarthSadist/mem0.git/': Could not resolve host: github.com`
   
   **Решение**:
   ```bash
   # Проверьте настройки сети Docker
   docker network inspect app-network
   
   # Проверьте доступность GitHub
   docker run --rm alpine sh -c "ping -c 3 github.com"
   
   # Убедитесь, что контейнер имеет доступ к интернету
   docker exec mem0 ping -c 3 github.com
   ```

### Проблемы с подключением к базе данных

1. **Ошибка подключения к PostgreSQL**:
   
   **Проблема**: `Error: connect ECONNREFUSED postgres:5432`
   
   **Решение**:
   ```bash
   # Проверьте, запущен ли контейнер PostgreSQL
   docker ps | grep postgres
   
   # Проверьте, что контейнеры находятся в одной сети
   docker network inspect app-network
   
   # Проверьте доступность PostgreSQL из контейнера Mem0
   docker exec mem0 nc -zv postgres 5432
   
   # Проверьте правильность учетных данных в .env
   docker exec -i postgres psql -U postgres -c "SELECT 1;"
   ```

2. **Ошибка подключения к Qdrant**:
   
   **Проблема**: `Error: connect ECONNREFUSED qdrant:6333`
   
   **Решение**:
   ```bash
   # Проверьте, запущен ли контейнер Qdrant
   docker ps | grep qdrant
   
   # Проверьте доступность Qdrant из контейнера Mem0
   docker exec mem0 nc -zv qdrant 6333
   
   # Проверьте логи Qdrant
   docker logs qdrant
   ```

3. **Ошибка аутентификации в базе данных**:
   
   **Проблема**: `Error: password authentication failed for user "postgres"`
   
   **Решение**:
   ```bash
   # Проверьте переменные окружения
   docker exec mem0 sh -c 'echo $DATABASE_URL'
   
   # Убедитесь, что пароль в .env файле соответствует паролю PostgreSQL
   docker exec -i postgres psql -U postgres -c "ALTER USER postgres WITH PASSWORD 'your_password';"
   
   # Обновите пароль в .env файле
   sudo sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=your_password/" /opt/.env
   
   # Перезапустите Mem0
   docker compose -f /opt/mem0-docker-compose.yaml --env-file /opt/.env restart
   ```

### Проблемы с API

1. **Ошибка аутентификации API**:
   
   **Проблема**: `{"error":"Unauthorized","message":"Invalid API key"}`
   
   **Решение**:
   ```bash
   # Проверьте API ключ в запросе
   curl -v -H "Authorization: Bearer YOUR_MEM0_API_KEY" https://mem0.yourdomain.com/api/health
   
   # Проверьте API ключ в .env файле
   docker exec mem0 sh -c 'echo $MEM0_API_KEY'
   
   # Убедитесь, что API ключ в запросе соответствует ключу в .env файле
   ```

2. **Ошибка при создании воспоминания**:
   
   **Проблема**: `{"error":"Bad Request","message":"Missing required field: user_id"}`
   
   **Решение**:
   ```bash
   # Проверьте формат запроса
   curl -X POST https://mem0.yourdomain.com/api/memories \
     -H "Authorization: Bearer YOUR_MEM0_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "user_id": "user123",
       "content": "Тестовое воспоминание",
       "type": "fact"
     }'
   
   # Убедитесь, что все обязательные поля присутствуют
   ```

3. **Ошибка при поиске воспоминаний**:
   
   **Проблема**: `{"error":"Internal Server Error","message":"Error generating embeddings"}`
   
   **Решение**:
   ```bash
   # Проверьте ключ OpenAI API
   docker exec mem0 sh -c 'echo $OPENAI_API_KEY'
   
   # Проверьте доступность API OpenAI
   docker exec mem0 curl -I https://api.openai.com/v1/models
   
   # Обновите ключ OpenAI API в .env файле
   sudo sed -i "s/OPENAI_API_KEY=.*/OPENAI_API_KEY=your_openai_api_key/" /opt/.env
   
   # Перезапустите Mem0
   docker compose -f /opt/mem0-docker-compose.yaml --env-file /opt/.env restart
   ```

### Проблемы с производительностью

1. **Медленные ответы API**:
   
   **Проблема**: API запросы выполняются слишком долго
   
   **Решение**:
   ```bash
   # Проверьте использование ресурсов
   docker stats mem0 postgres qdrant
   
   # Проверьте количество записей в базе данных
   docker exec -i postgres psql -U postgres -d mem0 -c "SELECT COUNT(*) FROM memories;"
   
   # Оптимизируйте индексы в базе данных
   docker exec -i postgres psql -U postgres -d mem0 -c "
   CREATE INDEX IF NOT EXISTS idx_memories_user_id ON memories(user_id);
   CREATE INDEX IF NOT EXISTS idx_memories_type ON memories(type);
   "
   
   # Увеличьте ресурсы контейнера в docker-compose.yaml
   ```

2. **Высокое использование CPU**:
   
   **Проблема**: Контейнер Mem0 использует слишком много CPU
   
   **Решение**:
   ```bash
   # Ограничьте использование CPU в docker-compose.yaml
   # Добавьте следующие строки в конфигурацию сервиса mem0:
   deploy:
     resources:
       limits:
         cpus: '1'
   
   # Оптимизируйте параметры запросов
   # Уменьшите limit в запросах поиска
   # Увеличьте relevance_threshold для более точных результатов
   ```

3. **Высокое использование памяти**:
   
   **Проблема**: Контейнер Mem0 использует слишком много памяти
   
   **Решение**:
   ```bash
   # Ограничьте использование памяти в docker-compose.yaml
   # Добавьте следующие строки в конфигурацию сервиса mem0:
   deploy:
     resources:
       limits:
         memory: 1G
   
   # Очистите устаревшие данные
   docker exec -i postgres psql -U postgres -d mem0 -c "
   DELETE FROM memories WHERE created_at < NOW() - INTERVAL '6 months';
   VACUUM FULL ANALYZE;
   "
   ```

### Проблемы с интеграцией

1. **Ошибка при интеграции с n8n**:
   
   **Проблема**: `Error: ECONNREFUSED - Connection refused by server`
   
   **Решение**:
   ```bash
   # Проверьте доступность Mem0 API из контейнера n8n
   docker exec n8n curl -I https://mem0.yourdomain.com/api/health
   
   # Убедитесь, что n8n имеет доступ к сети, в которой находится Mem0
   docker network connect app-network n8n
   
   # Проверьте настройки прокси в Caddy
   docker exec caddy cat /etc/caddy/Caddyfile | grep mem0
   ```

2. **Ошибка при интеграции с Flowise**:
   
   **Проблема**: `Error: Request failed with status code 401`
   
   **Решение**:
   ```bash
   # Проверьте API ключ в настройках Flowise
   # Убедитесь, что ключ соответствует значению MEM0_API_KEY в .env файле
   
   # Проверьте заголовок авторизации в запросе
   # Заголовок должен быть в формате "Authorization: Bearer YOUR_MEM0_API_KEY"
   ```

3. **Ошибка при интеграции с OpenAI**:
   
   **Проблема**: `Error: OpenAI API error: 401 - Invalid Authentication`
   
   **Решение**:
   ```bash
   # Проверьте ключ OpenAI API
   docker exec mem0 sh -c 'echo $OPENAI_API_KEY'
   
   # Убедитесь, что ключ действителен
   docker exec mem0 curl -H "Authorization: Bearer $OPENAI_API_KEY" https://api.openai.com/v1/models
   
   # Обновите ключ OpenAI API в .env файле
   sudo sed -i "s/OPENAI_API_KEY=.*/OPENAI_API_KEY=your_openai_api_key/" /opt/.env
   
   # Перезапустите Mem0
   docker compose -f /opt/mem0-docker-compose.yaml --env-file /opt/.env restart
   ```

### Проблемы с обновлением

1. **Ошибка при обновлении контейнера**:
   
   **Проблема**: `Error response from daemon: pull access denied for node, repository does not exist or may require 'docker login'`
   
   **Решение**:
   ```bash
   # Проверьте доступность Docker Hub
   docker run --rm alpine sh -c "ping -c 3 docker.io"
   
   # Попробуйте явно указать полный путь к образу
   docker pull docker.io/library/node:18-alpine
   
   # Перезапустите Mem0
   docker compose -f /opt/mem0-docker-compose.yaml --env-file /opt/.env up -d
   ```

2. **Ошибка при обновлении базы данных**:
   
   **Проблема**: `Error: relation "new_table" does not exist`
   
   **Решение**:
   ```bash
   # Проверьте структуру базы данных
   docker exec -i postgres psql -U postgres -d mem0 -c "\dt"
   
   # Выполните миграции базы данных
   docker exec mem0 npm run migrate
   
   # Если миграции не помогли, восстановите базу данных из резервной копии
   ```

3. **Конфликт версий при обновлении**:
   
   **Проблема**: Несовместимость новой версии с существующими данными
   
   **Решение**:
   ```bash
   # Создайте резервную копию перед обновлением
   docker run --rm -v mem0_data:/data -v $(pwd):/backup alpine tar -czf /backup/mem0_backup_$(date +%Y%m%d).tar.gz /data
   
   # Проверьте журнал изменений новой версии
   docker exec mem0 cat CHANGELOG.md
   
   # Выполните необходимые миграции данных
   # Если миграции не предусмотрены, обратитесь к документации проекта
   ```

### Общие рекомендации по устранению неполадок

1. **Проверка логов**:
   ```bash
   # Просмотр логов Mem0
   docker logs mem0
   
   # Просмотр логов PostgreSQL
   docker logs postgres
   
   # Просмотр логов Qdrant
   docker logs qdrant
   
   # Просмотр логов Caddy
   docker logs caddy
   ```

2. **Проверка конфигурации**:
   ```bash
   # Проверка переменных окружения
   docker compose -f /opt/mem0-docker-compose.yaml --env-file /opt/.env config
   
   # Проверка сетевых настроек
   docker network inspect app-network
   
   # Проверка томов
   docker volume inspect mem0_data
   ```

3. **Перезапуск сервисов**:
   ```bash
   # Перезапуск Mem0
   docker compose -f /opt/mem0-docker-compose.yaml --env-file /opt/.env restart
   
   # Перезапуск всего стека
   docker compose -f /opt/docker-compose.yaml --env-file /opt/.env restart
   ```

4. **Проверка доступности зависимостей**:
   ```bash
   # Проверка доступности PostgreSQL
   docker exec mem0 nc -zv postgres 5432
   
   # Проверка доступности Qdrant
   docker exec mem0 nc -zv qdrant 6333
   
   # Проверка доступности OpenAI API
   docker exec mem0 curl -I https://api.openai.com/v1/models
   ```

5. **Обновление зависимостей**:
   ```bash
   # Обновление образа Node.js
   docker pull node:18-alpine
   
   # Обновление образа PostgreSQL
   docker pull postgres:latest
   
   # Обновление образа Qdrant
   docker pull qdrant/qdrant:latest
   ```
## Часто задаваемые вопросы

### Общие вопросы

1. **Что такое Mem0?**
   
   Mem0 ("мем-зеро") - это интеллектуальный слой памяти для AI-ассистентов, который позволяет создавать персонализированные взаимодействия с пользователями. Сервис запоминает контекст общения, предпочтения пользователей и важную информацию, что позволяет AI-решениям адаптироваться к индивидуальным потребностям.

2. **Для чего нужен Mem0?**
   
   Mem0 решает проблему "амнезии" AI-систем, позволяя им запоминать информацию между сессиями и адаптировать ответы на основе предыдущих взаимодействий. Это делает взаимодействие с AI более естественным, персонализированным и эффективным.

3. **Какие преимущества дает использование Mem0?**
   
   - Персонализация взаимодействия с пользователями
   - Сохранение контекста между сессиями
   - Улучшение пользовательского опыта
   - Снижение необходимости повторно предоставлять одну и ту же информацию
   - Адаптация ответов AI на основе предпочтений пользователя
   - Возможность интеграции с различными AI-системами

4. **Какие технологии использует Mem0?**
   
   Mem0 использует:
   - PostgreSQL для хранения структурированных данных
   - Qdrant для хранения и поиска векторных эмбеддингов
   - OpenAI API для создания эмбеддингов и семантического поиска
   - REST API для взаимодействия с другими системами

5. **Является ли Mem0 open-source?**
   
   Да, Mem0 является проектом с открытым исходным кодом. Исходный код доступен на GitHub: https://github.com/DarthSadist/mem0

### Технические вопросы

6. **Какие системные требования у Mem0?**
   
   Минимальные требования:
   - Docker и Docker Compose
   - 1 ГБ оперативной памяти
   - 1 ядро CPU
   - 5 ГБ свободного дискового пространства
   
   Рекомендуемые требования:
   - 2+ ГБ оперативной памяти
   - 2+ ядра CPU
   - 20+ ГБ свободного дискового пространства

7. **Как Mem0 хранит данные?**
   
   Mem0 использует двойную систему хранения:
   - PostgreSQL для хранения структурированных данных (метаданные, текстовое содержимое)
   - Qdrant для хранения векторных эмбеддингов и выполнения семантического поиска

8. **Нужен ли мне ключ OpenAI API для использования Mem0?**
   
   Да, для работы Mem0 необходим действующий ключ OpenAI API, так как сервис использует модели OpenAI для создания эмбеддингов и семантического поиска. Ключ можно получить на сайте [OpenAI](https://platform.openai.com/api-keys).

9. **Можно ли использовать Mem0 без интернета?**
   
   Нет, Mem0 требует доступа к интернету для взаимодействия с API OpenAI. Без доступа к интернету функциональность сервиса будет ограничена.

10. **Какие модели OpenAI использует Mem0?**
    
    По умолчанию Mem0 использует модель `text-embedding-ada-002` для создания эмбеддингов. Эта модель оптимизирована для создания векторных представлений текста с хорошим соотношением качества и стоимости.

### Вопросы по интеграции

11. **С какими системами можно интегрировать Mem0?**
    
    Mem0 предоставляет REST API, что позволяет интегрировать его с любой системой, способной отправлять HTTP-запросы. В данном руководстве подробно описаны интеграции с:
    - n8n
    - Flowise
    
    Также возможна интеграция с:
    - Собственными приложениями
    - Другими платформами автоматизации
    - Чат-ботами
    - Веб-приложениями

12. **Как интегрировать Mem0 с n8n?**
    
    Интеграция с n8n осуществляется через HTTP Request ноды. Подробная инструкция и примеры представлены в разделе "Интеграция с n8n" данного руководства.

13. **Как интегрировать Mem0 с Flowise?**
    
    Интеграция с Flowise осуществляется через API ноды или с использованием компонентов LangChain. Подробная инструкция и примеры представлены в разделе "Интеграция с Flowise" данного руководства.

14. **Можно ли использовать Mem0 с LangChain?**
    
    Да, Mem0 можно интегрировать с LangChain, создав пользовательский класс памяти, который будет взаимодействовать с API Mem0. Пример такой интеграции представлен в разделе "Интеграция с Flowise".

15. **Как обеспечить безопасность при интеграции с Mem0?**
    
    Для обеспечения безопасности:
    - Используйте HTTPS для всех запросов к API
    - Храните API ключи в переменных окружения, а не в коде
    - Регулярно обновляйте API ключи
    - Ограничивайте доступ к API только необходимыми IP-адресами
    - Используйте минимально необходимые права доступа для интеграций

### Вопросы по использованию

16. **Как создать воспоминание в Mem0?**
    
    Для создания воспоминания отправьте POST-запрос к `/api/memories` с необходимыми параметрами. Пример запроса:
    ```bash
    curl -X POST https://mem0.yourdomain.com/api/memories \
      -H "Authorization: Bearer YOUR_MEM0_API_KEY" \
      -H "Content-Type: application/json" \
      -d '{
        "user_id": "user123",
        "content": "Пользователь предпочитает получать уведомления по email",
        "type": "preference"
      }'
    ```

17. **Как найти релевантные воспоминания?**
    
    Для поиска релевантных воспоминаний отправьте POST-запрос к `/api/memories/search` с параметрами поиска. Пример запроса:
    ```bash
    curl -X POST https://mem0.yourdomain.com/api/memories/search \
      -H "Authorization: Bearer YOUR_MEM0_API_KEY" \
      -H "Content-Type: application/json" \
      -d '{
        "user_id": "user123",
        "query": "Какие предпочтения по уведомлениям у пользователя?",
        "relevance_threshold": 0.7,
        "limit": 5
      }'
    ```

18. **Как удалить воспоминание?**
    
    Для удаления воспоминания отправьте DELETE-запрос к `/api/memories/:id`. Пример запроса:
    ```bash
    curl -X DELETE https://mem0.yourdomain.com/api/memories/mem_1234567890 \
      -H "Authorization: Bearer YOUR_MEM0_API_KEY"
    ```

19. **Как обновить существующее воспоминание?**
    
    Для обновления воспоминания отправьте PUT-запрос к `/api/memories/:id` с новыми данными. Пример запроса:
    ```bash
    curl -X PUT https://mem0.yourdomain.com/api/memories/mem_1234567890 \
      -H "Authorization: Bearer YOUR_MEM0_API_KEY" \
      -H "Content-Type: application/json" \
      -d '{
        "content": "Пользователь предпочитает получать уведомления по email и SMS"
      }'
    ```

20. **Как организовать воспоминания для разных пользователей?**
    
    Используйте уникальные `user_id` для каждого пользователя. Это позволит изолировать воспоминания разных пользователей и обеспечить персонализацию для каждого из них.

### Вопросы по обслуживанию

21. **Как часто нужно делать резервное копирование данных Mem0?**
    
    Рекомендуется делать резервное копирование данных не реже одного раза в неделю. При интенсивном использовании сервиса частоту можно увеличить до ежедневного копирования.

22. **Как оптимизировать производительность Mem0?**
    
    Для оптимизации производительности:
    - Регулярно очищайте устаревшие данные
    - Создайте индексы в базе данных PostgreSQL
    - Ограничьте количество возвращаемых воспоминаний в запросах
    - Увеличьте порог релевантности для более точных результатов
    - Настройте лимиты ресурсов для контейнеров

23. **Как обновить Mem0 до новой версии?**
    
    Для обновления Mem0:
    1. Создайте резервную копию данных
    2. Остановите контейнер: `docker compose -f /opt/mem0-docker-compose.yaml down`
    3. Удалите образ: `docker rmi node:18-alpine`
    4. Запустите сервис заново: `docker compose -f /opt/mem0-docker-compose.yaml --env-file /opt/.env up -d`

24. **Как мониторить состояние Mem0?**
    
    Для мониторинга:
    - Проверяйте логи: `docker logs mem0`
    - Отслеживайте использование ресурсов: `docker stats mem0`
    - Проверяйте доступность API: `curl -I https://mem0.yourdomain.com/api/health`
    - Настройте систему мониторинга (например, Prometheus + Grafana)

25. **Как очистить устаревшие данные в Mem0?**
    
    Для очистки устаревших данных:
    ```bash
    # Удаление воспоминаний старше 6 месяцев
    docker exec -i postgres psql -U postgres -d mem0 -c "DELETE FROM memories WHERE created_at < NOW() - INTERVAL '6 months';"
    
    # Оптимизация базы данных после удаления
    docker exec -i postgres psql -U postgres -d mem0 -c "VACUUM FULL ANALYZE;"
    ```

### Вопросы по безопасности

26. **Как защищены данные в Mem0?**
    
    Данные в Mem0 защищены следующими способами:
    - Аутентификация через API ключ
    - Шифрование HTTPS при передаче данных
    - Изоляция данных по пользователям
    - Контроль доступа к API

27. **Как часто нужно обновлять API ключи?**
    
    Рекомендуется обновлять API ключи не реже одного раза в 3 месяца, а также при подозрении на компрометацию ключа или при смене персонала, имевшего доступ к ключам.

28. **Можно ли ограничить доступ к API по IP-адресам?**
    
    Да, вы можете настроить ограничение доступа по IP-адресам в Caddy, добавив соответствующие правила в `Caddyfile`:
    ```
    mem0.$DOMAIN_NAME {
        @allowed_ips {
            remote_ip 192.168.1.0/24 10.0.0.0/8
        }
        reverse_proxy @allowed_ips mem0:3456
        respond 403
    }
    ```

29. **Как обеспечить соответствие требованиям GDPR?**
    
    Для соответствия GDPR:
    - Получайте явное согласие пользователей на хранение их данных
    - Предоставляйте возможность удаления всех данных пользователя
    - Ограничивайте срок хранения данных
    - Документируйте все операции с персональными данными
    - Обеспечивайте безопасность хранения и передачи данных

30. **Как удалить все данные определенного пользователя?**
    
    Для удаления всех данных пользователя:
    ```bash
    # Удаление всех воспоминаний пользователя из PostgreSQL
    docker exec -i postgres psql -U postgres -d mem0 -c "DELETE FROM memories WHERE user_id = 'user123';"
    
    # Удаление векторных эмбеддингов пользователя из Qdrant
    # (Конкретный запрос зависит от структуры коллекций в Qdrant)
    ```
