#!/bin/bash

USER="root"
PASS="root"
HOSTS=("192.168.100.5" "alt" "192.168.100.11" "astra" "192.168.100.9" "redos")
IFACE="enp0s3"

HOSTNAME=$(hostname | tr '[:upper:]' '[:lower:]')

echo "Определена система: $HOSTNAME"

# Получаем локальный IP текущей машины
LOCAL_IP=$(ip -4 addr show $IFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo "Локальный IP: $LOCAL_IP"

# Функция для настройки NAT и маршрутизатора
setup_router() {
    echo "Настройка маршрутизатора ($HOSTNAME)..."

    # Включаем маршрутизацию
    echo 1 > /proc/sys/net/ipv4/ip_forward
    sysctl -w net.ipv4.ip_forward=1

    # Настраиваем iptables NAT
    iptables -t nat -A POSTROUTING -o $IFACE -j MASQUERADE

    echo "NAT настроен через интерфейс $IFACE"

    # Обновим таблицы марршрутов на остальных хостах
    for ((i=0; i<${#HOSTS[@]}; i+=2)); do
        IP=${HOSTS[i]}
        NAME=${HOSTS[i+1]}

        if [[ "$IP" != "$LOCAL_IP" ]]; then
            echo "Настройка маршрута на $NAME ($IP)"
            sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$IP \
            "ip route replace default via $LOCAL_IP dev $IFACE && echo 'Шлюз обновлён на $LOCAL_IP'"
        fi
    done
}

# Основной выбор по названию системы
case "$HOSTNAME" in
  redos|alt|astra)
    setup_router
    ;;
  *)
    echo "[-] Неизвестное имя системы: $HOSTNAME. Скрипт завершнё."
    exit 1
    ;;
esac
