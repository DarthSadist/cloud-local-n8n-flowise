#!/bin/bash

# Функция проверки свободного места на диске
check_disk_space() {
    local required_space=$1 # в MB
    local mount_point=${2:-"/"}
    
    # Получаем свободное место в KB
    local free_space=$(df -k "$mount_point" | awk 'NR==2 {print $4}')
    # Переводим в MB для удобства сравнения
    local free_space_mb=$((free_space / 1024))
    
    if [ $free_space_mb -lt $required_space ]; then
        echo "❌ Недостаточно свободного места на диске $mount_point" >&2
        echo "Требуется: $required_space MB, Доступно: $free_space_mb MB" >&2
        return 1
    else
        echo "✅ Достаточно свободного места на диске $mount_point: $free_space_mb MB"
        return 0
    fi
}

# Функция очистки дискового пространства Docker
clean_docker_space() {
    echo "⚙️ Очистка неиспользуемых Docker ресурсов..."
    
    # Очистка неиспользуемых контейнеров
    echo "→ Удаление остановленных контейнеров..."
    sudo docker container prune -f
    
    # Очистка неиспользуемых образов
    echo "→ Удаление неиспользуемых образов..."
    sudo docker image prune -f
    
    # Очистка неиспользуемых томов
    echo "→ Удаление неиспользуемых томов..."
    sudo docker volume prune -f
    
    echo "✅ Очистка завершена. Текущее использование диска Docker:"
    sudo docker system df
}

# Экспортируем функции для использования в других скриптах
export -f check_disk_space
export -f clean_docker_space
