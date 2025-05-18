### Примеры кода для интеграции с Flowise

Ниже представлены готовые примеры кода для использования при интеграции Mem0 с Flowise:

#### 1. Класс для интеграции Mem0 с LangChain Memory

```javascript
// Код для создания пользовательского класса памяти для интеграции с LangChain
// Сохраните этот код в файле Mem0Memory.js

const axios = require('axios');

class Mem0Memory {
  constructor(config) {
    this.apiKey = config.apiKey;
    this.baseUrl = config.baseUrl || 'https://mem0.yourdomain.com';
    this.userId = config.userId || 'default_user';
    this.sessionId = config.sessionId || `session_${Date.now()}`;
    this.relevanceThreshold = config.relevanceThreshold || 0.7;
    this.limit = config.limit || 5;
  }

  async saveContext(inputValues, outputValues) {
    try {
      // Формирование содержимого воспоминания
      const content = `Пользователь спросил: ${inputValues.input}. Ответ: ${outputValues.output}`;
      
      // Отправка запроса к API Mem0
      await axios.post(
        `${this.baseUrl}/api/memories`,
        {
          user_id: this.userId,
          session_id: this.sessionId,
          content: content,
          type: "interaction",
          metadata: {
            source: "flowise",
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
      
      console.log('Interaction saved to Mem0');
      return true;
    } catch (error) {
      console.error('Error saving to Mem0:', error.message);
      return false;
    }
  }

  async loadMemoryVariables(values) {
    try {
      // Формирование запроса поиска
      const query = values.input || '';
      
      // Отправка запроса к API Mem0
      const response = await axios.post(
        `${this.baseUrl}/api/memories/search`,
        {
          user_id: this.userId,
          query: query,
          relevance_threshold: this.relevanceThreshold,
          limit: this.limit,
          types: ["preference", "fact", "interaction"]
        },
        {
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json'
          }
        }
      );
      
      // Обработка результатов поиска
      let memoryString = "";
      if (response.data.memories && response.data.memories.length > 0) {
        memoryString = "Предыдущий контекст:\n";
        
        // Группировка воспоминаний по типу
        const facts = response.data.memories.filter(m => m.type === "fact");
        const preferences = response.data.memories.filter(m => m.type === "preference");
        const interactions = response.data.memories.filter(m => m.type === "interaction");
        
        // Добавление фактов
        if (facts.length > 0) {
          memoryString += "\nФакты:\n";
          facts.forEach(fact => {
            memoryString += `- ${fact.content}\n`;
          });
        }
        
        // Добавление предпочтений
        if (preferences.length > 0) {
          memoryString += "\nПредпочтения:\n";
          preferences.forEach(pref => {
            memoryString += `- ${pref.content}\n`;
          });
        }
        
        // Добавление последних взаимодействий
        if (interactions.length > 0) {
          memoryString += "\nПоследние взаимодействия:\n";
          interactions
            .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
            .slice(0, 3)
            .forEach(inter => {
              memoryString += `- ${inter.content}\n`;
            });
        }
      }
      
      console.log('Memories loaded from Mem0');
      return { memory: memoryString };
    } catch (error) {
      console.error('Error loading from Mem0:', error.message);
      return { memory: "" };
    }
  }
}

module.exports = { Mem0Memory };
```

#### 2. Код для узла API в Flowise для создания воспоминания

```javascript
// Код для создания воспоминания через API узел в Flowise

// Получение входных данных
const userId = inputs.userId || "default_user";
const content = inputs.content || "";
const type = inputs.type || "interaction";
const sessionId = inputs.sessionId || `session_${Date.now()}`;

// Формирование данных для запроса
const requestData = {
  url: "https://mem0.yourdomain.com/api/memories",
  method: "POST",
  headers: {
    "Authorization": `Bearer ${inputs.apiKey}`,
    "Content-Type": "application/json"
  },
  data: {
    user_id: userId,
    content: content,
    type: type,
    session_id: sessionId,
    metadata: {
      source: "flowise",
      timestamp: new Date().toISOString()
    }
  }
};

// Возвращение настроек для API узла
return requestData;
```

#### 3. Код для узла API в Flowise для поиска воспоминаний

```javascript
// Код для поиска воспоминаний через API узел в Flowise

// Получение входных данных
const userId = inputs.userId || "default_user";
const query = inputs.query || "";
const relevanceThreshold = inputs.relevanceThreshold || 0.7;
const limit = inputs.limit || 5;

// Формирование данных для запроса
const requestData = {
  url: "https://mem0.yourdomain.com/api/memories/search",
  method: "POST",
  headers: {
    "Authorization": `Bearer ${inputs.apiKey}`,
    "Content-Type": "application/json"
  },
  data: {
    user_id: userId,
    query: query,
    relevance_threshold: relevanceThreshold,
    limit: limit,
    types: ["preference", "fact", "interaction"]
  }
};

// Возвращение настроек для API узла
return requestData;
```

#### 4. Код для узла Code в Flowise для обработки результатов поиска

```javascript
// Код для обработки результатов поиска воспоминаний
// Для использования в узле Code в Flowise

// Получение результатов поиска
const memories = inputs.memories || [];
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
return { userContext: contextString };
```

#### 5. Код для узла Code в Flowise для формирования системного промпта

```javascript
// Код для формирования системного промпта с использованием контекста из Mem0
// Для использования в узле Code в Flowise

// Получение контекста из предыдущего узла
const userContext = inputs.userContext || "";

// Формирование системного промпта
const systemPrompt = `
Ты - полезный ассистент. Используй следующую информацию о пользователе для персонализации ответа:

${userContext}

Дай персонализированный ответ, учитывая предпочтения и историю взаимодействий пользователя.
Если контекст не содержит релевантной информации для ответа, используй общие знания.
`;

// Возвращение системного промпта для использования в узле ChatOpenAI
return { systemPrompt };
```

#### 6. Код для узла Code в Flowise для автоматического извлечения важной информации

```javascript
// Код для автоматического извлечения важной информации из ответа LLM
// Для использования в узле Code в Flowise после узла ChatOpenAI

// Получение сообщения пользователя и ответа LLM
const userMessage = inputs.userMessage || "";
const llmResponse = inputs.llmResponse || "";

// Формирование промпта для анализа
const analysisPrompt = `
Проанализируй следующее сообщение пользователя и ответ ассистента.
Извлеки из них важную информацию, которую стоит запомнить для будущих взаимодействий.
Верни результат в формате JSON:
{
  "should_remember": true/false,
  "content": "Извлеченная информация в виде факта",
  "type": "fact/preference/interaction"
}

Сообщение пользователя: ${userMessage}
Ответ ассистента: ${llmResponse}
`;

// Возвращение промпта для анализа
return { analysisPrompt };
```
