 # Установка n8n, Flowise и Qdrant локально в облаке

Скрипт для автоматической установки n8n, Flowise и Qdrant с обратным прокси-сервером Caddy для безопасного доступа по HTTPS.
Также включает Adminer для удобного управления базой данных PostgreSQL и Crawl4AI для веб-скрапинга.
Включает Watchtower для автоматического обновления контейнеров.
Включает Netdata для мониторинга производительности в реальном времени.

## Описание

Этот репозиторий содержит скрипты для автоматической настройки:

- **n8n** - мощная платформа автоматизации рабочих процессов с открытым исходным кодом.
  - Настроена для использования **PostgreSQL** для постоянного хранения данных.
- **Flowise** - инструмент для создания настраиваемых AI-потоков.
- **Qdrant** - векторная база данных для эффективного поиска по сходству и AI-приложений.
- **Adminer** - легковесный инструмент управления базами данных (для PostgreSQL).
- **Crawl4AI** - веб-краулер, разработанный для сбора данных для AI.
- **PostgreSQL** - надежная объектно-реляционная система баз данных.
  - Включает расширение **pgvector** для хранения векторных эмбеддингов и поиска по сходству.
- **Redis** - хранилище структур данных в памяти (может использоваться для кеширования, очередей и т.д.).
- **Caddy** - современный веб-сервер с автоматическим HTTPS.
- **Watchtower** - автоматически обновляет запущенные Docker-контейнеры до последней версии образа.
- **Netdata** - система мониторинга производительности систем и приложений в реальном времени.

## Требования

- Ubuntu 22.04
- Доменное имя, указывающее на IP-адрес вашего сервера
- Доступ к серверу с правами администратора (sudo)
- Открытые порты 80, 443

## Установка

1.  Клонируйте репозиторий:
    ```bash
    git clone https://github.com/miolamio/cloud-local-n8n-flowise.git && cd cloud-local-n8n-flowise
    ```

2.  Сделайте скрипт исполняемым:
    ```bash
    chmod +x setup.sh
    ```

3.  Запустите скрипт установки:
    ```bash
    ./setup.sh
    ```

4.  Следуйте инструкциям в терминале:
    - Введите ваше доменное имя (например, example.com)
    - Введите ваш email (будет использоваться для входа в n8n и для Let's Encrypt)
    - Введите ваш часовой пояс (например, Europe/Moscow)

## Что делает скрипт установки

1.  **Обновление системы** (`01-update-system.sh`) - обновляет список пакетов и устанавливает необходимые зависимости.
2.  **Установка Docker** (`02-install-docker.sh`) - устанавливает Docker Engine и Docker Compose.
3.  **Создание Docker Volumes** (`03-create-volumes.sh`) - создает необходимые внешние Docker-тома.
4.  **Настройка директорий и пользователя** (`03b-setup-directories.sh`) - создает пользователя n8n, необходимые директории и устанавливает права.
5.  **Генерация секретов** (`04-generate-secrets.sh`) - создает случайные пароли и ключи, сохраняет их в `/opt/.env` и временно в `setup-files/passwords.txt`.
6.  **Создание конфигурационных файлов** (`05-create-templates.sh`) - генерирует файлы docker-compose и Caddyfile из шаблонов, используя переменные из `/opt/.env`, и копирует их в `/opt/`. Копирует `pgvector-init.sql`.
7.  **Настройка брандмауэра** (`06-setup-firewall.sh`) - открывает необходимые порты (80, 443).
8.  **Запуск сервисов** (`07-start-services.sh`) - запускает все Docker-контейнеры, используя конфигурации из `/opt/`. Удаляет временный файл `setup-files/passwords.txt`.

## Доступ к сервисам

После завершения установки вы сможете получить доступ к сервисам по следующим URL:

- **n8n**: https://n8n.ваш-домен.xxx
- **Flowise**: https://flowise.ваш-домен.xxx
- **Adminer**: https://adminer.ваш-домен.xxx
- **Qdrant**: https://qdrant.ваш-домен.xxx (Веб-интерфейс Qdrant. Доступ к API требует ключа `QDRANT_API_KEY` из файла `/opt/.env`)
- **Crawl4AI**: https://crawl4ai.ваш-домен.xxx (доступ к API, вероятно, потребует сгенерированный `CRAWL4AI_JWT_SECRET` из `/opt/.env`)
- **Netdata**: https://netdata.ваш-домен.xxx

Watchtower работает в фоновом режиме и не имеет веб-интерфейса.

Учетные данные для входа в n8n, Flowise, PostgreSQL будут отображены в конце процесса установки и сохранены в `/opt/.env`.

**Подключение к PostgreSQL через Adminer:**
*   Перейдите по адресу `https://adminer.ваш-домен.xxx`.
*   Система (System): `PostgreSQL`
*   Сервер (Server): `n8n_postgres` (Это имя сервиса в сети Docker)
*   Имя пользователя (Username): (Используйте `POSTGRES_USER` из вывода установки или `/opt/.env`)
*   Пароль (Password): (Используйте `POSTGRES_PASSWORD` из вывода установки или `/opt/.env`)
*   База данных (Database): (Используйте `POSTGRES_DB` из вывода установки или `/opt/.env`)

**Доступ к Crawl4AI API:**
*   Сервис Crawl4AI доступен по адресу `https://crawl4ai.ваш-домен.xxx`.
*   Запросы к API, скорее всего, потребуют токен аутентификации (Bearer Token), использующий `CRAWL4AI_JWT_SECRET`, найденный в `/opt/.env`.

## Структура проекта

- `setup.sh` - основной скрипт установки
- `setup-files/` - директория со вспомогательными скриптами:
  - `01-update-system.sh` - обновление системы
  - `02-install-docker.sh` - установка Docker
  - `03-create-volumes.sh` - создание Docker-томов
  - `03b-setup-directories.sh` - настройка директорий и пользователя
  - `04-generate-secrets.sh` - генерация секретных ключей
  - `05-create-templates.sh` - создание конфигурационных файлов из шаблонов
  - `06-setup-firewall.sh` - настройка брандмауэра
  - `07-start-services.sh` - запуск сервисов
  - `10-backup-data.sh` - скрипт для создания резервных копий важных Docker-томов
- `n8n-docker-compose.yaml.template` - шаблон docker-compose для n8n, PostgreSQL, Redis, Caddy и Adminer
- `flowise-docker-compose.yaml.template` - шаблон docker-compose для Flowise
- `qdrant-docker-compose.yaml.template` - шаблон docker-compose для Qdrant
- `crawl4ai-docker-compose.yaml.template` - шаблон docker-compose для Crawl4AI
- `watchtower-docker-compose.yaml.template` - шаблон docker-compose для Watchtower
- `netdata-docker-compose.yaml.template` - шаблон docker-compose для Netdata
- `Caddyfile.template` - шаблон конфигурации для Caddy
- `.env.template` - шаблон файла переменных окружения
- `pgvector-init.sql` - скрипт инициализации расширения pgvector для PostgreSQL

## Управление сервисами

Команды следует выполнять из любой директории, так как они используют абсолютные пути к файлам конфигурации в `/opt/`.

### Перезапуск сервисов

```bash
sudo docker compose -f /opt/n8n-docker-compose.yaml --env-file /opt/.env restart
sudo docker compose -f /opt/flowise-docker-compose.yaml --env-file /opt/.env restart
sudo docker compose -f /opt/qdrant-docker-compose.yaml --env-file /opt/.env restart
sudo docker compose -f /opt/crawl4ai-docker-compose.yaml --env-file /opt/.env restart
sudo docker compose -f /opt/watchtower-docker-compose.yaml restart # .env не нужен
sudo docker compose -f /opt/netdata-docker-compose.yaml --env-file /opt/.env restart # .env может понадобиться для имени хоста
```

### Остановка сервисов

```bash
sudo docker compose -f /opt/n8n-docker-compose.yaml --env-file /opt/.env down
sudo docker compose -f /opt/flowise-docker-compose.yaml --env-file /opt/.env down
sudo docker compose -f /opt/qdrant-docker-compose.yaml --env-file /opt/.env down
sudo docker compose -f /opt/crawl4ai-docker-compose.yaml --env-file /opt/.env down
sudo docker compose -f /opt/watchtower-docker-compose.yaml down
sudo docker compose -f /opt/netdata-docker-compose.yaml --env-file /opt/.env down
```

### Просмотр логов

```bash
sudo docker compose -f /opt/n8n-docker-compose.yaml --env-file /opt/.env logs -f --tail 100
sudo docker compose -f /opt/flowise-docker-compose.yaml --env-file /opt/.env logs -f --tail 100
sudo docker compose -f /opt/qdrant-docker-compose.yaml --env-file /opt/.env logs -f --tail 100
sudo docker compose -f /opt/crawl4ai-docker-compose.yaml --env-file /opt/.env logs -f --tail 100
sudo docker compose -f /opt/watchtower-docker-compose.yaml logs -f --tail 100
sudo docker compose -f /opt/netdata-docker-compose.yaml --env-file /opt/.env logs -f --tail 100
```

## Резервное копирование и восстановление

Включен базовый скрипт резервного копирования для защиты ваших данных.

**Создание резервных копий:**

1.  Перейдите в директорию проекта: `cd /путь/к/cloud-local-n8n-flowise`
2.  Запустите скрипт резервного копирования: `sudo ./setup-files/10-backup-data.sh`

Этот скрипт:
*   Создаст резервные копии следующих Docker-томов: `n8n_data`, `n8n_postgres_data`, `n8n_redis_data`, `flowise_data`, `qdrant_storage`, `caddy_data`, `caddy_config`.
*   Сохранит резервные копии в виде файлов `.tar.gz` с временной меткой в `/opt/backups/`.
*   Автоматически удалит резервные копии старше 7 дней (настраивается в скрипте).
*   **Консистентность данных:** Скрипт **автоматически останавливает** основные сервисы (n8n, Flowise, Qdrant, Crawl4AI) перед созданием резервной копии и **перезапускает** их после завершения. Это обеспечивает консистентность данных баз данных.

**Важно:**
*   **Место на диске:** Убедитесь, что у вас достаточно места на диске в `/opt/backups/`.
*   **Внешние резервные копии:** Регулярно копируйте содержимое `/opt/backups/` в отдельное, безопасное место (например, на другой сервер, в облачное хранилище).

**Восстановление из резервных копий (Ручной процесс):**

Восстановление требует ручного извлечения файла `.tar.gz` в соответствующий Docker-том. Этот процесс более сложен и зависит от конкретного сервиса.

1.  **Остановите** сервис, данные которого вы хотите восстановить (например, `sudo docker compose -f /opt/n8n-docker-compose.yaml stop n8n_postgres`).
2.  Определите правильное имя Docker-тома (например, `n8n_postgres_data`).
3.  При необходимости, **переименуйте или удалите** существующий том, если вы хотите выполнить чистое восстановление: `sudo docker volume rm n8n_postgres_data` (**Используйте с крайней осторожностью!**).
4.  Создайте том заново, если он был удален: `sudo docker volume create n8n_postgres_data`.
5.  Используйте временный контейнер для извлечения архива резервной копии в том:
    ```bash
    sudo docker run --rm \
        -v n8n_postgres_data:/pgdata \
        -v /opt/backups:/backup \
        alpine \
        tar xzf /backup/postgres_YYYYMMDD_HHMMSS.tar.gz -C /pgdata
    ```
    (Замените имена томов, пути и имена архивов соответствующим образом).
*Примечание: Восстановление томов Caddy (`caddy_data`, `caddy_config`) в идеале следует выполнять при остановленном Caddy. Эти тома содержат SSL-сертификаты и состояние конфигурации.*
6.  При необходимости проверьте права доступа/владельца внутри тома (особенно для PostgreSQL).
7.  **Перезапустите** сервис.

## Безопасность

- Все сервисы доступны только по HTTPS с автоматически обновляемыми сертификатами Let's Encrypt.
- Для n8n, Flowise, PostgreSQL создаются случайные пароли.
- Пользователи создаются с минимально необходимыми привилегиями.
- Adminer предоставляет веб-интерфейс для управления базой данных n8n PostgreSQL.
- Безопасный доступ к API Crawl4AI с использованием сгенерированного `CRAWL4AI_JWT_SECRET` в качестве Bearer-токена в ваших запросах.
- **Автоматические обновления:** Watchtower отслеживает Docker Hub и автоматически обновляет контейнеры (n8n, Flowise и т.д.) при появлении новых официальных образов (проверка по умолчанию ежедневно в 4 утра). Это помогает поддерживать ваши сервисы в актуальном состоянии с исправлениями безопасности и новыми функциями.
- **Мониторинг производительности:** Netdata предоставляет панель мониторинга в реальном времени, доступную через веб-браузер, показывающую подробные метрики для CPU, RAM, дискового ввода-вывода, сетевого трафика, Docker-контейнеров и многого другого.
- **Удаление временных файлов:** Временный файл `setup-files/passwords.txt`, содержащий пароли для первоначального отображения пользователю, удаляется после успешного завершения установки для повышения безопасности.

## Устранение неполадок

- Проверьте DNS-записи вашего домена, чтобы убедиться, что они указывают на правильный IP-адрес.
- Убедитесь, что порты 80 и 443 открыты на вашем сервере.
- Просмотрите логи контейнеров для обнаружения ошибок.
- Убедитесь, что n8n/Flowise настроены для подключения к `http://qdrant:6333`. Если вы включили API-ключ Qdrant, убедитесь, что он указан в настройках подключения в n8n/Flowise.
- При подключении через Adminer убедитесь, что вы используете *имя сервиса Docker* (`n8n_postgres`) в качестве сервера/хоста, а не `localhost` или IP-адрес.