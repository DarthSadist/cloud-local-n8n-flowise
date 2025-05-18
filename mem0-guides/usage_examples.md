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
