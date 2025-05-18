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
