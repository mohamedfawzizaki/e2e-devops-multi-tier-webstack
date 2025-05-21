#!/bin/bash

set -e
export DEBIAN_FRONTEND=noninteractive

MYSQL_ROOT_PASSWORD="root"
REMOTE_USER="mo"
REMOTE_PASS="29112000"

echo "== Update APT =="
sudo apt-get update

echo "== Install MySQL =="
sudo apt-get install -y debconf-utils
echo "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections
sudo apt-get install -y mysql-server

echo "== Allow MySQL on all interfaces =="
sudo sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

echo "== Secure MySQL =="
sudo mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<-EOF
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db LIKE 'test\\_%';
FLUSH PRIVILEGES;
EOF

echo "== Create Remote Users =="
IFS=',' read -ra HOST_ARRAY <<< "$REMOTE_HOSTS"
for HOST in "${HOST_ARRAY[@]}"; do
  sudo mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<-EOF
  CREATE USER IF NOT EXISTS '${REMOTE_USER}'@'$HOST' IDENTIFIED BY '${REMOTE_PASS}';
  GRANT ALL PRIVILEGES ON *.* TO '${REMOTE_USER}'@'$HOST' WITH GRANT OPTION;
EOF
done
sudo mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

echo "== Setup Firewall =="
sudo ufw allow OpenSSH
sudo ufw allow 3306/tcp
sudo ufw --force enable

echo "== Done =="
