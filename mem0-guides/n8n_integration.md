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
