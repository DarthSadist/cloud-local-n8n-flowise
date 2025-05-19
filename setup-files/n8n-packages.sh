#!/bin/bash

# Скрипт для управления npm-пакетами в n8n

ACTION=$1
PACKAGE=$2
VERSION=$3

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Функция для проверки наличия контейнера n8n
check_n8n_container() {
    if ! docker ps | grep -q "n8n"; then
        echo -e "${RED}❌ Контейнер n8n не запущен${NC}"
        echo -e "${YELLOW}Запустите n8n с помощью команды:${NC} sudo ./setup-files/07-start-services.sh"
        exit 1
    fi
}

# Функция для сохранения списка установленных пакетов
save_packages_list() {
    echo -e "${YELLOW}📋 Сохранение списка установленных пакетов...${NC}"
    docker exec n8n npm list -g --depth=0 > /opt/n8n-packages.txt
    echo -e "${GREEN}✅ Список пакетов сохранен в /opt/n8n-packages.txt${NC}"
}

# Проверка наличия аргументов
if [ -z "$ACTION" ]; then
    echo -e "${RED}❌ Не указано действие${NC}"
    echo -e "${YELLOW}Использование:${NC} $0 {install|remove|list|update} [package] [version]"
    exit 1
fi

case "$ACTION" in
    install)
        if [ -z "$PACKAGE" ]; then
            echo -e "${RED}❌ Не указан пакет для установки${NC}"
            echo -e "${YELLOW}Использование:${NC} $0 install <package> [version]"
            exit 1
        fi
        
        # Проверка наличия контейнера n8n
        check_n8n_container
        
        INSTALL_CMD="npm install -g $PACKAGE"
        if [ -n "$VERSION" ]; then
            INSTALL_CMD="$INSTALL_CMD@$VERSION"
        fi
        
        echo -e "${YELLOW}📦 Установка пакета $PACKAGE...${NC}"
        docker exec n8n $INSTALL_CMD
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Пакет $PACKAGE успешно установлен${NC}"
            # Обновляем список установленных пакетов
            save_packages_list
        else
            echo -e "${RED}❌ Ошибка при установке пакета $PACKAGE${NC}"
            exit 1
        fi
        ;;
        
    remove)
        if [ -z "$PACKAGE" ]; then
            echo -e "${RED}❌ Не указан пакет для удаления${NC}"
            echo -e "${YELLOW}Использование:${NC} $0 remove <package>"
            exit 1
        fi
        
        # Проверка наличия контейнера n8n
        check_n8n_container
        
        echo -e "${YELLOW}🗑️ Удаление пакета $PACKAGE...${NC}"
        docker exec n8n npm uninstall -g $PACKAGE
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Пакет $PACKAGE успешно удален${NC}"
            # Обновляем список установленных пакетов
            save_packages_list
        else
            echo -e "${RED}❌ Ошибка при удалении пакета $PACKAGE${NC}"
            exit 1
        fi
        ;;
        
    list)
        # Проверка наличия контейнера n8n
        check_n8n_container
        
        echo -e "${YELLOW}📋 Список установленных пакетов:${NC}"
        docker exec n8n npm list -g --depth=0
        ;;
        
    update)
        # Проверка наличия контейнера n8n
        check_n8n_container
        
        if [ -z "$PACKAGE" ]; then
            echo -e "${YELLOW}📦 Обновление всех пакетов...${NC}"
            docker exec n8n npm update -g
        else
            echo -e "${YELLOW}📦 Обновление пакета $PACKAGE...${NC}"
            docker exec n8n npm update -g $PACKAGE
        fi
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Пакеты успешно обновлены${NC}"
            # Обновляем список установленных пакетов
            save_packages_list
        else
            echo -e "${RED}❌ Ошибка при обновлении пакетов${NC}"
            exit 1
        fi
        ;;
        
    *)
        echo -e "${RED}❌ Неизвестное действие: $ACTION${NC}"
        echo -e "${YELLOW}Использование:${NC} $0 {install|remove|list|update} [package] [version]"
        exit 1
        ;;
esac
