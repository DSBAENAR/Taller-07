#!/bin/bash
# ============================================================
# Creates a systemd service for the Spring Boot application
# ============================================================

set -e

echo "=== Creating systemd service file ==="
sudo tee /etc/systemd/system/secureapp.service > /dev/null <<EOF
[Unit]
Description=SecureApp Spring Boot Service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/spring-backend
ExecStart=/usr/bin/java -jar /home/ec2-user/spring-backend/target/secure-app-1.0.0.jar
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "=== Enabling and starting service ==="
sudo systemctl daemon-reload
sudo systemctl enable secureapp
sudo systemctl start secureapp

echo "=== Service status ==="
sudo systemctl status secureapp

echo ""
echo "Useful commands:"
echo "  sudo systemctl status secureapp   - Check status"
echo "  sudo systemctl restart secureapp  - Restart"
echo "  sudo journalctl -u secureapp -f   - View logs"
