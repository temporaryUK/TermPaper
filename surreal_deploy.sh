#!/bin/bash


SERVERS=(192.168.100.5 192.168.100.11 192.168.100.9)
NAMES=(alt astra redos)
PASSWORD=root

get_free_mem() {
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@$1 "free -m | awk '/Mem:/ {print \$4}'"
}

declare -A mem_map

for i in "${!SERVERS[@]}"; do
    mem=$(get_free_mem "${SERVERS[$i]}")
    mem_map["${SERVERS[$i]}"]=$mem
    echo "${NAMES[$i]} (${SERVERS[$i]}) has $mem MB free"
done

# Find min/max
min_ip=$(for ip in "${!mem_map[@]}"; do echo "$ip ${mem_map[$ip]}"; done | sort -k2 -nr | tail -1 | awk '{print $1}')
max_ip=$(for ip in "${!mem_map[@]}"; do echo "$ip ${mem_map[$ip]}"; done | sort -k2 -nr | head -1 | awk '{print $1}')

echo "Installing SurrealDB on least loaded server: $min_ip"
sshpass -p "$PASSWORD" ssh root@$min_ip "curl -sSf https://install.surrealdb.com | sh && surreal start --user root --pass root --log debug &"

echo "Configuring $max_ip as NAT router"
sshpass -p "$PASSWORD" ssh root@$max_ip "
  echo 1 > /proc/sys/net/ipv4/ip_forward
  iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
"

# Update /etc/hosts on all machines
for i in "${!SERVERS[@]}"; do
  for j in "${!SERVERS[@]}"; do
    sshpass -p "$PASSWORD" ssh root@${SERVERS[$i]} "echo '${SERVERS[$j]} ${NAMES[$j]}' >> /etc/hosts"
  done
done
