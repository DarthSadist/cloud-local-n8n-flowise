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
