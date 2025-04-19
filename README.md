# Автоматическая установка n8n, Flowise, Qdrant и других сервисов

Этот проект представляет собой набор скриптов для автоматизированной установки и настройки стека сервисов для работы с AI и автоматизацией рабочих процессов. Все сервисы развертываются в Docker-контейнерах и доступны через безопасные HTTPS-соединения благодаря Caddy.

## Включенные сервисы

- **n8n** - платформа автоматизации рабочих процессов с низкокодовым интерфейсом
  - Настроена для использования PostgreSQL для постоянного хранения данных
  - Включает Redis для очередей и кеширования
- **Flowise** - интерфейс для создания LLM-приложений и чат-цепочек
- **Qdrant** - векторная база данных для хранения и поиска эмбеддингов
  - Защищен API-ключом для безопасного доступа
- **Crawl4AI** - веб-сервис для сбора данных и их обработки
- **PostgreSQL** - реляционная база данных с расширением pgvector
- **Adminer** - веб-интерфейс для управления базами данных
- **Caddy** - веб-сервер с автоматическим получением SSL-сертификатов
- **Watchtower** - сервис для автоматического обновления Docker-контейнеров
- **Netdata** - система мониторинга в реальном времени

## Системные требования

- Ubuntu 22.04 LTS или другой совместимый дистрибутив Linux
- Минимум 2 ГБ RAM (рекомендуется 4+ ГБ)
- Минимум 20 ГБ дискового пространства
- Настроенное доменное имя, указывающее на IP вашего сервера
- Открытые порты 80 и 443

## Быстрая установка

1. Клонируйте репозиторий:
   ```bash
   git clone https://github.com/DarthSadist/cloud-local-n8n-flowise.git
   cd cloud-local-n8n-flowise
   ```

2. Запустите установочный скрипт:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. Следуйте инструкциям в терминале:
   - Введите ваше доменное имя
   - Укажите email для Let's Encrypt и авторизации в n8n
   - Подтвердите часовой пояс

## Доступ к сервисам

После успешной установки сервисы будут доступны по следующим адресам:

- **n8n**: https://n8n.ваш-домен
- **Flowise**: https://flowise.ваш-домен
- **Adminer**: https://adminer.ваш-домен
- **Qdrant**: https://qdrant.ваш-домен
- **Crawl4AI**: https://crawl4ai.ваш-домен
- **Netdata**: https://netdata.ваш-домен

## Учетные данные

Все учетные данные генерируются автоматически и сохраняются в файле `/opt/.env`. В конце установки вам будут показаны основные логины и пароли.

### Для n8n:
- **Логин**: email, указанный при установке
- **Пароль**: автоматически сгенерированный (см. в `/opt/.env`)

### Для Flowise:
- **Логин**: admin
- **Пароль**: автоматически сгенерированный (см. в `/opt/.env`)

### Для PostgreSQL (через Adminer):
- **Сервер**: postgres
- **Имя пользователя**: n8n
- **Пароль**: автоматически сгенерированный (см. в `/opt/.env`)
- **База данных**: n8n

### Для Qdrant:
- **API-ключ**: автоматически сгенерированный (см. в `/opt/.env`)

### Для Crawl4AI:
- **JWT-секрет**: автоматически сгенерированный (см. в `/opt/.env`)

## Управление сервисами

### Проверка статуса контейнеров
```bash
sudo docker ps
```

### Перезапуск сервисов
```bash
# Перезапуск n8n и связанных сервисов (PostgreSQL, Redis, Caddy)
sudo docker compose -f /opt/n8n-docker-compose.yaml --env-file /opt/.env restart

# Перезапуск Flowise
sudo docker compose -f /opt/flowise-docker-compose.yaml --env-file /opt/.env restart

# Перезапуск Qdrant
sudo docker compose -f /opt/qdrant-docker-compose.yaml --env-file /opt/.env restart

# Перезапуск Crawl4AI
sudo docker compose -f /opt/crawl4ai-docker-compose.yaml --env-file /opt/.env restart

# Перезапуск Watchtower
sudo docker compose -f /opt/watchtower-docker-compose.yaml restart

# Перезапуск Netdata
sudo docker compose -f /opt/netdata-docker-compose.yaml restart
```

### Остановка сервисов
```bash
sudo docker compose -f /opt/n8n-docker-compose.yaml --env-file /opt/.env down
sudo docker compose -f /opt/flowise-docker-compose.yaml --env-file /opt/.env down
sudo docker compose -f /opt/qdrant-docker-compose.yaml --env-file /opt/.env down
sudo docker compose -f /opt/crawl4ai-docker-compose.yaml --env-file /opt/.env down
sudo docker compose -f /opt/watchtower-docker-compose.yaml down
sudo docker compose -f /opt/netdata-docker-compose.yaml down
```

### Просмотр логов
```bash
# Просмотр логов n8n
sudo docker logs n8n

# Просмотр логов Flowise
sudo docker logs flowise

# Просмотр логов Qdrant
sudo docker logs qdrant

# Просмотр логов Caddy
sudo docker logs caddy
```

## Резервное копирование

Для создания резервных копий всех данных:

1. Запустите скрипт резервного копирования:
   ```bash
   sudo ./setup-files/10-backup-data.sh
   ```

2. Резервные копии будут сохранены в директории `/opt/backups/` в виде `.tar.gz` архивов с датой и временем.

3. Рекомендуется регулярно копировать эти резервные копии в надежное хранилище.

## Восстановление из резервных копий

1. Остановите сервис, данные которого нужно восстановить, например:
   ```bash
   sudo docker compose -f /opt/n8n-docker-compose.yaml stop n8n
   ```

2. Используйте временный контейнер для восстановления данных:
   ```bash
   sudo docker run --rm \
       -v n8n_data:/restore_dest \
       -v /opt/backups:/backups \
       alpine \
       tar xzf /backups/n8n_data_YYYYMMDD_HHMMSS.tar.gz -C /restore_dest
   ```

3. Перезапустите сервис:
   ```bash
   sudo docker compose -f /opt/n8n-docker-compose.yaml start n8n
   ```

## Структура проекта

- `setup.sh` - основной скрипт установки
- `setup-files/` - скрипты для отдельных этапов установки:
  - `01-update-system.sh` - обновление системы
  - `02-install-docker.sh` - установка Docker
  - `03-create-volumes.sh` - создание Docker-томов
  - `03b-setup-directories.sh` - настройка директорий
  - `04-generate-secrets.sh` - генерация секретных ключей
  - `05-create-templates.sh` - создание файлов конфигурации
  - `06-setup-firewall.sh` - настройка брандмауэра
  - `07-start-services.sh` - запуск сервисов
  - `check_disk_space.sh` - проверка свободного места
  - `10-backup-data.sh` - создание резервных копий
- Файлы шаблонов `*.template` для создания конфигураций Docker Compose и Caddy

## Безопасность

- Все сервисы доступны только по HTTPS с автоматически обновляемыми сертификатами Let's Encrypt
- Для всех сервисов генерируются случайные надежные пароли
- API Qdrant защищен API-ключом
- API Crawl4AI защищен JWT-аутентификацией
- Все тома Docker настроены для сохранения данных между перезапусками

## Устранение неполадок

### Проблемы с Caddy
Если Caddy не запускается или не удается получить сертификаты:
```bash
sudo docker logs caddy
```

### Диагностика всего стека
Запустите диагностический скрипт:
```bash
./setup-diag.sh
```

### Очистка неиспользуемых ресурсов Docker
Если заканчивается место на диске:
```bash
sudo docker system prune -a
```

## Лицензия

Данный проект распространяется под лицензией MIT.

## Контакты

При возникновении вопросов или проблем, пожалуйста, создайте issue в этом репозитории.
