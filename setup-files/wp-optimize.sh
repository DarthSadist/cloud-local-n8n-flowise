#!/bin/bash

# Скрипт для оптимизации WordPress и установки плагинов кеширования

echo "================================================================="
echo "🚀 Настройка оптимизации WordPress"
echo "================================================================="

# Проверка наличия контейнера WordPress
if ! sudo docker ps | grep -q "wordpress"; then
  echo "❌ WordPress не запущен. Запустите сначала контейнер WordPress."
  exit 1
fi

# Проверка наличия WP-CLI в контейнере
echo "Проверка и настройка WP-CLI..."
sudo docker exec -it wordpress bash -c "wp --allow-root --version || ( \
  apt-get update && \
  apt-get install -y curl && \
  curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
  chmod +x wp-cli.phar && \
  mv wp-cli.phar /usr/local/bin/wp )"

# Ожидание инициализации WordPress
echo "Ожидание инициализации WordPress..."
MAX_ATTEMPTS=10
ATTEMPTS=0
WP_READY=false

while [ $ATTEMPTS -lt $MAX_ATTEMPTS ] && [ "$WP_READY" = false ]; do
  if sudo docker exec -it wordpress bash -c "wp core is-installed --allow-root" 2>/dev/null; then
    WP_READY=true
    echo "✅ WordPress успешно инициализирован!"
  else
    ((ATTEMPTS++))
    echo "⏳ WordPress еще не готов. Попытка $ATTEMPTS из $MAX_ATTEMPTS. Ожидание 10 секунд..."
    sleep 10
  fi
done

if [ "$WP_READY" = false ]; then
  echo "⚠️ WordPress не был инициализирован в течение ожидаемого времени."
  echo "⚠️ Возможно, вам нужно сначала настроить WordPress через веб-интерфейс."
  echo "⚠️ После настройки запустите этот скрипт снова."
  exit 1
fi

# Установка и активация плагинов оптимизации
echo "Установка плагинов оптимизации..."

# W3 Total Cache - популярный плагин кеширования
sudo docker exec -it wordpress bash -c "wp plugin install w3-total-cache --activate --allow-root"
echo "✅ Установлен W3 Total Cache"

# WP-Optimize - очистка базы данных и оптимизация изображений
sudo docker exec -it wordpress bash -c "wp plugin install wp-optimize --activate --allow-root"
echo "✅ Установлен WP-Optimize"

# Smush - оптимизация изображений
sudo docker exec -it wordpress bash -c "wp plugin install wp-smushit --activate --allow-root"
echo "✅ Установлен Smush для оптимизации изображений"

# Autoptimize - оптимизация CSS и JavaScript
sudo docker exec -it wordpress bash -c "wp plugin install autoptimize --activate --allow-root"
echo "✅ Установлен Autoptimize"

# Другие рекомендуемые плагины
echo "Установка дополнительных полезных плагинов..."

# Classic Editor - для тех, кто предпочитает классический редактор
sudo docker exec -it wordpress bash -c "wp plugin install classic-editor --allow-root"

# Wordfence Security - плагин для безопасности
sudo docker exec -it wordpress bash -c "wp plugin install wordfence --allow-root"

# UpdraftPlus - плагин для резервного копирования
sudo docker exec -it wordpress bash -c "wp plugin install updraftplus --allow-root"

# Настройка WordPress для лучшей производительности
echo "Применение оптимизаций WordPress..."

# Отключение автообновлений и ревизий для снижения нагрузки на базу данных
sudo docker exec -it wordpress bash -c "wp config set WP_AUTO_UPDATE_CORE false --allow-root"
sudo docker exec -it wordpress bash -c "wp config set WP_POST_REVISIONS 3 --allow-root"
sudo docker exec -it wordpress bash -c "wp config set AUTOSAVE_INTERVAL 300 --allow-root"

# Установка лимитов памяти и времени выполнения
sudo docker exec -it wordpress bash -c "wp config set WP_MEMORY_LIMIT 128M --allow-root"
sudo docker exec -it wordpress bash -c "wp config set WP_MAX_MEMORY_LIMIT 256M --allow-root"

# Очистка базы данных от мусора
echo "Очистка базы данных от мусора..."
sudo docker exec -it wordpress bash -c "wp db optimize --allow-root"

echo "================================================================="
echo "✅ Оптимизация WordPress успешно завершена!"
echo "================================================================="
echo "Установленные плагины оптимизации:"
echo "  - W3 Total Cache (кеширование)"
echo "  - WP-Optimize (очистка БД и оптимизация)"
echo "  - Smush (оптимизация изображений)"
echo "  - Autoptimize (оптимизация CSS и JavaScript)"
echo ""
echo "Дополнительные установленные плагины:"
echo "  - Classic Editor"
echo "  - Wordfence Security"
echo "  - UpdraftPlus (для резервного копирования)"
echo ""
echo "Для дальнейшей настройки плагинов, пожалуйста, войдите в админ-панель WordPress."
echo "https://wordpress.ваш-домен/wp-admin/"
echo "================================================================="

exit 0