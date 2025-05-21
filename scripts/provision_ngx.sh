#!/bin/bash

# Install Nginx
sudo apt-get update
sudo apt-get install -y nginx

# Remove default Nginx config
sudo rm /etc/nginx/sites-enabled/default

# Test and restart Nginx
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx


sudo ufw allow 'Nginx HTTP'
sudo ufw enable