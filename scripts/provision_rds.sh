#!/usr/bin/env bash

set -e

REDIS_PASSWORD="29112000"

# Parse comma-separated REMOTE_HOSTS from environment into an array
IFS=',' read -ra IP_LIST <<< "$REMOTE_HOSTS"

echo ">>> Installing Redis server"
sudo apt-get update
sudo apt-get install -y redis-server ufw

echo ">>> Securing Redis configuration"
sudo sed -i '/^requirepass /d' /etc/redis/redis.conf
echo "requirepass $REDIS_PASSWORD" | sudo tee -a /etc/redis/redis.conf > /dev/null
sudo sed -i 's/^bind 127\.0\.0\.1 ::1$/bind 0.0.0.0/' /etc/redis/redis.conf

echo ">>> Restarting Redis"
sudo systemctl restart redis-server
sudo systemctl enable redis-server

echo ">>> Setting up firewall rules"
sudo ufw allow OpenSSH

# Loop over allowed IPs and allow each one to access port 6379
for ip in "${IP_LIST[@]}"; do
  echo "Allowing Redis access from $ip"
  sudo ufw allow from "$ip" to any port 6379
done

sudo ufw --force enable

echo ">>> Verifying Redis is protected"
sleep 2
if echo "PING" | redis-cli -a "$REDIS_PASSWORD" | grep -q PONG; then
  echo ">>> Redis is up and secured with password authentication."
else
  echo ">>> Redis authentication test failed." >&2
  exit 1
fi

echo ">>> Redis secured and ready!"
