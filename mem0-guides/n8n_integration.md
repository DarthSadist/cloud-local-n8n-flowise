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

### Примеры кода для узла Code в n8n

Ниже представлены готовые примеры кода для использования в узле Code при интеграции с Mem0:

#### 1. Создание воспоминания

```javascript
// Код для создания нового воспоминания в Mem0
// Для использования в узле Code в n8n

// Получение данных из предыдущего узла
const userId = $input.item.json.userId || "default_user";
const content = $input.item.json.message || "";
const type = $input.item.json.type || "interaction";

// Формирование данных для запроса
const memoryData = {
  user_id: userId,
  content: content,
  type: type,
  session_id: $input.item.json.sessionId || `session_${new Date().getTime()}`,
  metadata: {
    source: "n8n_workflow",
    timestamp: new Date().toISOString(),
    workflow_name: $workflow.name,
    workflow_id: $workflow.id
  }
};

// Настройка параметров для следующего узла HTTP Request
return {
  json: {
    memoryData,
    apiUrl: "https://mem0.yourdomain.com/api/memories",
    apiKey: $env.MEM0_API_KEY // Требуется настроить переменную окружения
  }
};
```

#### 2. Поиск релевантных воспоминаний

```javascript
// Код для поиска релевантных воспоминаний в Mem0
// Для использования в узле Code в n8n

// Получение данных из предыдущего узла
const userId = $input.item.json.userId || "default_user";
const query = $input.item.json.query || "";

// Формирование запроса поиска
const searchQuery = {
  user_id: userId,
  query: query,
  relevance_threshold: 0.7,
  limit: 5,
  types: ["preference", "fact", "interaction"]
};

// Настройка параметров для следующего узла HTTP Request
return {
  json: {
    searchQuery,
    apiUrl: "https://mem0.yourdomain.com/api/memories/search",
    apiKey: $env.MEM0_API_KEY // Требуется настроить переменную окружения
  }
};
```
### Примеры кода для узла Code в n8n

Ниже представлены готовые примеры кода для использования в узле Code при интеграции с Mem0:

#### 1. Создание воспоминания

```javascript
// Код для создания нового воспоминания в Mem0
// Для использования в узле Code в n8n

// Получение данных из предыдущего узла
const userId = $input.item.json.userId || "default_user";
const content = $input.item.json.message || "";
const type = $input.item.json.type || "interaction";

// Формирование данных для запроса
const memoryData = {
  user_id: userId,
  content: content,
  type: type,
  session_id: $input.item.json.sessionId || `session_${new Date().getTime()}`,
  metadata: {
    source: "n8n_workflow",
    timestamp: new Date().toISOString(),
    workflow_name: $workflow.name,
    workflow_id: $workflow.id
  }
};

// Настройка параметров для следующего узла HTTP Request
return {
  json: {
    memoryData,
    apiUrl: "https://mem0.yourdomain.com/api/memories",
    apiKey: $env.MEM0_API_KEY // Требуется настроить переменную окружения
  }
};
```

#### 2. Поиск релевантных воспоминаний

```javascript
// Код для поиска релевантных воспоминаний в Mem0
// Для использования в узле Code в n8n

// Получение данных из предыдущего узла
const userId = $input.item.json.userId || "default_user";
const query = $input.item.json.query || "";

// Формирование запроса поиска
const searchQuery = {
  user_id: userId,
  query: query,
  relevance_threshold: 0.7,
  limit: 5,
  types: ["preference", "fact", "interaction"]
};

// Настройка параметров для следующего узла HTTP Request
return {
  json: {
    searchQuery,
    apiUrl: "https://mem0.yourdomain.com/api/memories/search",
    apiKey: $env.MEM0_API_KEY // Требуется настроить переменную окружения
  }
};
```

#### 3. Обработка результатов поиска

```javascript
// Код для обработки результатов поиска воспоминаний
// Для использования в узле Code после HTTP Request к Mem0

// Получение результатов поиска из предыдущего узла
const memories = $input.item.json.memories || [];
let contextString = "";

// Формирование контекста из воспоминаний
if (memories.length > 0) {
  contextString = "Информация о пользователе:\n";
  
  // Группировка воспоминаний по типу
  const facts = memories.filter(m => m.type === "fact");
  const preferences = memories.filter(m => m.type === "preference");
  const interactions = memories.filter(m => m.type === "interaction");
  
  // Добавление фактов
  if (facts.length > 0) {
    contextString += "\nФакты:\n";
    facts.forEach(fact => {
      contextString += `- ${fact.content}\n`;
    });
  }
  
  // Добавление предпочтений
  if (preferences.length > 0) {
    contextString += "\nПредпочтения:\n";
    preferences.forEach(pref => {
      contextString += `- ${pref.content}\n`;
    });
  }
  
  // Добавление последних взаимодействий
  if (interactions.length > 0) {
    contextString += "\nПоследние взаимодействия:\n";
    interactions
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
      .slice(0, 3)
      .forEach(inter => {
        contextString += `- ${inter.content}\n`;
      });
  }
}

// Возвращение контекста для использования в последующих узлах
return {
  json: {
    userContext: contextString,
    hasMemories: memories.length > 0,
    memoryCount: memories.length
  }
};
```

#### 4. Формирование промпта для LLM с использованием контекста

```javascript
// Код для формирования промпта для LLM с использованием контекста из Mem0
// Для использования в узле Code перед узлом OpenAI

// Получение данных из предыдущих узлов
const userContext = $input.item.json.userContext || "";
const userQuery = $input.item.json.query || "";

// Формирование промпта с учетом контекста
const prompt = `
Ты - полезный ассистент. Используй следующую информацию о пользователе для персонализации ответа:

${userContext}

Вопрос пользователя: ${userQuery}

Дай персонализированный ответ, учитывая предпочтения и историю взаимодействий пользователя.
Если контекст не содержит релевантной информации для ответа, используй общие знания.
`;

// Возвращение промпта для использования в узле OpenAI
return {
  json: {
    prompt: prompt,
    model: "gpt-4",
    temperature: 0.7,
    max_tokens: 500
  }
};
```

#### 5. Автоматическое извлечение важной информации из сообщения пользователя

```javascript
// Код для автоматического извлечения важной информации из сообщения пользователя
// Для использования в узле Code после узла OpenAI, который анализирует сообщение

// Получение результата анализа от OpenAI
const analysis = $input.item.json.analysis || {};
const shouldRemember = analysis.should_remember === true;
const content = analysis.content || "";
const type = analysis.type || "fact";
const userId = $input.item.json.userId || "default_user";

// Проверка необходимости сохранения информации
if (shouldRemember && content.trim() !== "") {
  // Формирование данных для сохранения в Mem0
  const memoryData = {
    user_id: userId,
    content: content,
    type: type,
    metadata: {
      source: "auto_extraction",
      timestamp: new Date().toISOString(),
      original_message: $input.item.json.original_message || ""
    }
  };
  
  // Возвращение данных для сохранения
  return {
    json: {
      shouldSave: true,
      memoryData,
      apiUrl: "https://mem0.yourdomain.com/api/memories",
      apiKey: $env.MEM0_API_KEY
    }
  };
} else {
  // Если нет необходимости сохранять информацию
  return {
    json: {
      shouldSave: false,
      reason: "No relevant information to save or extraction failed"
    }
  };
}
```

#### 6. Периодическая очистка устаревших воспоминаний

```javascript
// Код для периодической очистки устаревших воспоминаний
// Для использования в узле Code в рабочем процессе, запускаемом по расписанию

// Настройка параметров очистки
const userId = $input.item.json.userId || "all";
const olderThan = new Date();
olderThan.setMonth(olderThan.getMonth() - 6); // Воспоминания старше 6 месяцев
const olderThanStr = olderThan.toISOString();

// Формирование запроса для получения старых воспоминаний
const queryParams = userId === "all" 
  ? `created_before=${olderThanStr}`
  : `user_id=${userId}&created_before=${olderThanStr}`;

// Настройка параметров для следующего узла HTTP Request
return {
  json: {
    apiUrl: `https://mem0.yourdomain.com/api/memories?${queryParams}`,
    apiKey: $env.MEM0_API_KEY,
    method: "GET",
    cleanupDate: olderThanStr,
    userId: userId
  }
};
```
