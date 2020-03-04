#!/bin/bash
sudo apt-get install -y apt-transport-https
sudo apt-get install -y software-properties-common wget
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -

# Alternatively you can add the beta repository, see in the table above
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"

sudo apt-get update
sudo apt-get install grafana nginx -y
sudo systemctl daemon-reload
sudo systemctl enable grafana-server 
sudo systemctl start grafana-server

sudo apt-get install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp

ufw enable

ufw status verbose
cat <<EOF > default
server {
  listen 80;
  root /usr/share/nginx/html;
  index index.html index.htm;

  location / {
   proxy_pass http://localhost:3000/;
  }
}
EOF

sudo mv default /etc/nginx/sites-available/default

sudo nginx -t && nginx -s reload

exit 0