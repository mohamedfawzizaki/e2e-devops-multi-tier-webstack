#!/bin/bash

# Exit on any error
set -e

# Parse comma-separated REMOTE_HOSTS from environment into an array
IFS=',' read -ra IP_LIST <<< "$REMOTE_HOSTS"

# Set app directory and entry point
APP_DIR="/node-app"
APP_ENTRY="server.js" 
cd "$APP_DIR"

echo "Updating package list..."
sudo apt-get update

echo "Installing prerequisites..."
sudo apt-get install -y curl build-essential

echo "Setting up NodeSource for Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

echo "Installing Node.js and npm..."
sudo apt-get install -y nodejs

echo "Verifying Node.js and npm installation..."
node -v
npm -v

echo "Installing necessary npm packages..."
# sudo npm install -g nodemon
sudo npm install -g pm2
sudo npm install mysql2
sudo npm install ioredis

# Ensure PM2 can run on system startup
pm2 startup systemd -u vagrant --hp /home/vagrant
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u vagrant --hp /home/vagrant

# Create .pm2ignore to prevent unnecessary restarts
echo "Creating .pm2ignore file..."
cat <<EOF > "$APP_DIR/.pm2ignore"
logs
.git
README.md
*.log
node_modules
EOF

# Start app with watch mode if entry file exists
if [ -f "$APP_DIR/$APP_ENTRY" ]; then
  echo "Starting Node.js app with PM2 (watch mode enabled)..."
  pm2 start "$APP_ENTRY" --watch --name server
  pm2 save
else
  echo "No Node.js entry file found at $APP_DIR/$APP_ENTRY"
fi

echo ">>> Setting up firewall rules"
sudo ufw allow OpenSSH
# Loop over allowed IPs and allow each one to access port 3000
for ip in "${IP_LIST[@]}"; do
  echo "Allowing Node access from $ip to access port 3000"
  sudo ufw allow from "$ip" to any port 3000
done

echo "Provisioning complete!"
