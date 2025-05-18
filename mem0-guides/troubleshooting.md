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
