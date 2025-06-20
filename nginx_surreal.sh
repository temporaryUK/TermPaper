#!/bin/bash

ASTRA_IP="192.168.100.11"
SURR_HOST_PORT="8000"
NGINX_PORT="80"

apt update && apt install -y nginx
cat > /etc/nginx/sites-available/surreal_proxy <<EOF
server {
    listen $NGINX_PORT;

    location / {
        allow $ASTRA_IP;
        deny all;

        proxy_pass http://localhost:$SURR_HOST_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

ln -s /etc/nginx/sites-available/surreal_proxy /etc/nginx/sites-enabled/surreal_proxy
rm -f /etc/nginx/sites-enabled/default

systemctl restart nginx
