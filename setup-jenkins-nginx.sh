#!/bin/bash

# Exit on any error
set -e

echo "🔄 Updating system..."
sudo apt update && sudo apt upgrade -y

echo "☕ Installing Java (required by Jenkins)..."
sudo apt install openjdk-17-jdk -y

echo "📦 Adding Jenkins repo and key..."
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "📥 Installing Jenkins..."
sudo apt update
sudo apt install jenkins -y

echo "🚀 Starting and enabling Jenkins..."
sudo systemctl start jenkins
sudo systemctl enable jenkins

echo "🌐 Installing Nginx..."
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx

echo "🔧 Configuring Nginx as reverse proxy for Jenkins..."
cat <<EOF | sudo tee /etc/nginx/sites-available/jenkins
server {
    listen 80;
    server_name jenkins.example.com;

    location / {
        proxy_pass         http://localhost:8080;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
    }
}
EOF

echo "🔗 Enabling the Jenkins Nginx config..."
sudo ln -sf /etc/nginx/sites-available/jenkins /etc/nginx/sites-enabled/jenkins
sudo rm -f /etc/nginx/sites-enabled/default

echo "✅ Testing and reloading Nginx..."
sudo nginx -t && sudo systemctl reload nginx

echo "🔓 Allowing HTTP traffic through firewall (if UFW is enabled)..."
sudo ufw allow 80 || true
sudo ufw allow 8080 || true

echo "✅ Setup complete!"

echo "👉 NEXT STEP:"
echo "Add the following line to your local machine's /etc/hosts (Linux/macOS) or C:\\Windows\\System32\\drivers\\etc\\hosts (Windows):"
echo
echo "$(curl -s http://checkip.amazonaws.com) jenkins.example.com"
echo
echo "Then open: http://jenkins.example.com in your browser"
echo "To get your Jenkins initial admin password, run:"
echo "  sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
