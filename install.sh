#!/bin/bash

# ==============================================================================
# MTProxy Auto-Installer with Sponsor Tag Integration
# Based on: https://github.com/statix05/MTProxyInstall
# Author: Domain Expert Analysis
# ==============================================================================

set -e

# Определение цветовой схемы для терминала
info='\033]; then
        echo -e "${err}Ошибка: Данный скрипт должен быть запущен с правами root (sudo).${nc}"
        exit 1
    fi
}

# Проверка и установка зависимостей
install_dependencies() {
    echo -e "${info}[*] Проверка системных зависимостей...${nc}"
    if! command -v curl &> /dev/null ||! command -v xxd &> /dev/null; then
        apt-get update && apt-get install -y curl xxd
    fi
}

# Основной цикл конфигурации
configure_proxy() {
    print_header
    
    # Определение внешнего IP
    SERVER_IP=$(curl -s https://api.ipify.org |

| echo "ВАШ_IP")
    
    # Запрос порта
    read -p "Введите порт для прокси (по умолчанию 8443): " PROXY_PORT
    PROXY_PORT=${PROXY_PORT:-8443}
    
    # Генерация секрета
    SECRET=$(head -c 16 /dev/urandom | xxd -ps)
    
    echo -e "\n${info}[*] Сгенерированы предварительные данные для регистрации:${nc}"
    echo -e "${warn}IP: ${SERVER_IP}${nc}"
    echo -e "${warn}Порт: ${PROXY_PORT}${nc}"
    echo -e "${warn}Секрет: ${SECRET}${nc}"
    echo -e "${info}----------------------------------------------------------------${nc}"
    
    # Интерактивный запрос спонсорского тега
    echo -e "Желаете ли вы добавить спонсорский тег для продвижения канала?"
    echo -e "Для этого вам необходимо:"
    echo -e "1. Открыть бота @MTProxybot в Telegram."
    echo -e "2. Отправить команду /newproxy."
    echo -e "3. Ввести данные сервера (указаны выше)."
    echo -e "4. Бот выдаст вам 'Proxy Tag'.\n"
    
    read -p "Введите Sponsor Tag (оставьте пустым, если не хотите добавлять): " SPONSOR_TAG
    
    if]; then
        echo -e "${info}[*] Установка будет продолжена без спонсорского канала.${nc}"
    else
        echo -e "${info}[*] Тег принят: $SPONSOR_TAG${nc}"
    fi
}

# Развертывание Docker
deploy_docker() {
    echo -e "${info}[*] Подготовка Docker-окружения...${nc}"
    if! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com | sh
        systemctl enable --now docker
    fi
}

# Запуск контейнера
run_container() {
    echo -e "${info}[*] Запуск контейнера MTProxy...${nc}"
    
    # Остановка старых инстансов
    docker stop mtproxy &> /dev/null |

| true
    docker rm mtproxy &> /dev/null |

| true
    
    # Формирование команды запуска
    DOCKER_CMD="docker run -d --name mtproxy --restart always -p $PROXY_PORT:443 -v proxy-config:/data -e SECRET=$SECRET"
    
    if]; then
        DOCKER_CMD+=" -e TAG=$SPONSOR_TAG"
    fi
    
    DOCKER_CMD+=" telegrammessenger/proxy:latest"
    
    # Выполнение
    eval $DOCKER_CMD
}

# Настройка брандмауэра
configure_firewall() {
    echo -e "${info}[*] Настройка правил сетевого экрана...${nc}"
    if command -v ufw &> /dev/null; then
        ufw allow "$PROXY_PORT"/tcp
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port="$PROXY_PORT"/tcp
        firewall-cmd --reload
    fi
}

# Завершение установки и вывод информации
print_summary() {
    echo -e "\n${info}Установка успешно завершена!${nc}"
    echo -e "Данные для подключения:"
    echo -e "${warn}tg://proxy?server=${SERVER_IP}&port=${PROXY_PORT}&secret=${SECRET}${nc}"
    echo -e "Ссылка с защитой от DPI (рекомендуется):"
    echo -e "${warn}tg://proxy?server=${SERVER_IP}&port=${PROXY_PORT}&secret=dd${SECRET}${nc}"
    
    # Создание утилиты управления (аналог statix05)
    cat <<EOF > /usr/local/bin/mtproxy
#!/bin/bash
case \$1 in
    status) docker ps -f name=mtproxy ;;
    logs) docker logs mtproxy ;;
    info) echo "IP: $SERVER_IP, Port: $PROXY_PORT, Secret: $SECRET" ;;
    restart) docker restart mtproxy ;;
    *) echo "Использование: mtproxy {status|logs|info|restart}" ;;
esac
EOF
    chmod +x /usr/local/bin/mtproxy
    echo -e "${info}[*] Утилита управления установлена: 'mtproxy status'${nc}"
}

# Выполнение функций
check_root
install_dependencies
configure_proxy
deploy_docker
run_container
configure_firewall
print_summary
