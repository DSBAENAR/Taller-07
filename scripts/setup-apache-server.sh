#!/bin/bash
# ============================================================
# Setup Script for Server 1: Apache HTTP Server with TLS
# Run this on an Amazon Linux 2023 EC2 instance
# ============================================================

set -e

echo "=== Updating system packages ==="
sudo dnf update -y

echo "=== Installing Apache HTTP Server ==="
sudo dnf install -y httpd mod_ssl

echo "=== Starting and enabling Apache ==="
sudo systemctl start httpd
sudo systemctl enable httpd

echo "=== Installing Certbot for Let's Encrypt ==="
sudo dnf install -y augeas-libs pip
sudo pip install certbot
sudo pip install certbot-apache

echo "=== Configuring firewall ==="
# If firewalld is running
if systemctl is-active --quiet firewalld; then
    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --permanent --add-service=https
    sudo firewall-cmd --reload
fi

echo "=== Deploying client application ==="
sudo cp /home/ec2-user/apache-client/* /var/www/html/

echo "=== Setting permissions ==="
sudo chown -R apache:apache /var/www/html/
sudo chmod -R 755 /var/www/html/

echo "============================================"
echo "Apache server setup complete!"
echo ""
echo "NEXT STEPS:"
echo "1. Make sure your domain DNS A record points to this EC2 instance's public IP"
echo "2. Run the following to get a Let's Encrypt TLS certificate:"
echo "   sudo certbot --apache -d YOUR_DOMAIN"
echo ""
echo "3. Update the API_BASE_URL in /var/www/html/app.js"
echo "   to point to your Spring server: https://YOUR_SPRING_DOMAIN:8443"
echo ""
echo "4. Restart Apache: sudo systemctl restart httpd"
echo "============================================"
