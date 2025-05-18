# Интеграция Mem0 с n8n и Flowise

## Обзор

[Mem0](https://github.com/DarthSadist/mem0) - это система для создания интеллектуального слоя памяти для AI-ассистентов, позволяющая им запоминать пользовательские предпочтения и адаптироваться к индивидуальным потребностям.

## Возможности

- **Многоуровневая память**: Сохранение состояния пользователя, сессии и агента с адаптивной персонализацией
- **Удобство для разработчиков**: Интуитивно понятный API, кросс-платформенные SDK
- **Интеграция с существующими сервисами**: Работает совместно с n8n и Flowise

## Настройка

### Переменные окружения

В файле `.env` настроены следующие переменные для Mem0:

```
MEM0_API_KEY=<случайно сгенерированный ключ>
OPENAI_API_KEY=sk-your-openai-api-key
MEM0_HOST=0.0.0.0
MEM0_PORT=3456
```

**Важно**: Замените `OPENAI_API_KEY` на ваш реальный ключ API OpenAI.

### Доступ к сервису

После запуска сервис Mem0 доступен по адресу:
- https://mem0.yourdomain.com

## Интеграция с n8n

### Создание HTTP-запросов к Mem0 API

1. Создайте новый рабочий процесс в n8n
2. Добавьте ноду HTTP Request
3. Настройте запрос к API Mem0:
   - URL: `http://mem0:3456/api/memories`
   - Метод: `POST`
   - Заголовки: 
     ```
     {
       "Content-Type": "application/json",
       "Authorization": "Bearer {{$env.MEM0_API_KEY}}"
     }
     ```
   - Тело запроса:
     ```json
     {
       "user_id": "user123",
       "memory": "Пользователь предпочитает получать уведомления по email",
       "metadata": {
         "source": "user_preferences",
         "confidence": 0.95
       }
     }
     ```

### Получение памяти

```
GET http://mem0:3456/api/memories?user_id=user123
```

## Интеграция с Flowise

Для интеграции Mem0 с Flowise можно использовать:

1. **Компонент Custom Tool**: Создайте инструмент для взаимодействия с Mem0 API
2. **Компонент Custom API**: Создайте API для доступа к функциям Mem0
3. **Компонент Memory**: Используйте Mem0 как источник памяти для LLM-цепочек

### Пример интеграции с LangChain

```javascript
const { Memory } = require('mem0ai');
const memory = new Memory();

// Добавление памяти
await memory.add([
  { role: "user", content: "Мой любимый цвет - синий" },
  { role: "assistant", content: "Я запомню, что ваш любимый цвет - синий" }
], { user_id: "user123" });

// Поиск релевантной памяти
const memories = await memory.search({
  query: "Какой у меня любимый цвет?",
  user_id: "user123",
  limit: 5
});
```

## Мониторинг и обслуживание

### Просмотр логов

```bash
docker logs mem0
```

### Перезапуск сервиса

```bash
docker compose -f /opt/mem0-docker-compose.yaml restart
```

## Резервное копирование

Данные Mem0 хранятся в томе Docker `mem0_data`. Для резервного копирования используйте:

```bash
docker run --rm -v mem0_data:/data -v $(pwd):/backup alpine tar -czf /backup/mem0_backup.tar.gz /data
```

## Устранение неполадок

### Проблемы с подключением к API

1. Проверьте, запущен ли контейнер: `docker ps | grep mem0`
2. Проверьте логи: `docker logs mem0`
3. Проверьте настройки в файле `.env`

### Проблемы с интеграцией OpenAI

1. Убедитесь, что вы указали правильный ключ API OpenAI в `.env`
2. Проверьте доступность API OpenAI из контейнера
