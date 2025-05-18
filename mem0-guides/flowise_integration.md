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
