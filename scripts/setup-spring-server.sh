#!/bin/bash
# ============================================================
# Setup Script for Server 2: Spring Boot API with TLS
# Run this on an Amazon Linux 2023 EC2 instance
# ============================================================

set -e

DOMAIN="${1:-your-spring-domain.com}"

echo "=== Updating system packages ==="
sudo dnf update -y

echo "=== Installing Java 17 ==="
sudo dnf install -y java-17-amazon-corretto-devel

echo "=== Installing Maven ==="
sudo dnf install -y maven

echo "=== Installing Certbot for Let's Encrypt ==="
sudo dnf install -y augeas-libs pip
sudo pip install certbot

echo "=== Configuring firewall ==="
if systemctl is-active --quiet firewalld; then
    sudo firewall-cmd --permanent --add-port=8443/tcp
    sudo firewall-cmd --reload
fi

echo "=== Building Spring Boot application ==="
cd /home/ec2-user/spring-backend
mvn clean package -DskipTests

echo "============================================"
echo "Spring server setup complete!"
echo ""
echo "NEXT STEPS:"
echo "1. Get a Let's Encrypt certificate:"
echo "   sudo certbot certonly --standalone -d $DOMAIN"
echo ""
echo "2. Convert the certificate to PKCS12 format:"
echo "   sudo openssl pkcs12 -export \\"
echo "     -in /etc/letsencrypt/live/$DOMAIN/fullchain.pem \\"
echo "     -inkey /etc/letsencrypt/live/$DOMAIN/privkey.pem \\"
echo "     -out /etc/letsencrypt/live/$DOMAIN/keystore.p12 \\"
echo "     -name tomcat -password pass:changeit"
echo ""
echo "3. Update application.properties:"
echo "   - Uncomment the TLS configuration lines"
echo "   - Set the key-store path to the .p12 file"
echo "   - Update allowed-origins with your Apache domain"
echo ""
echo "4. Run the application:"
echo "   java -jar target/secure-app-1.0.0.jar"
echo ""
echo "Or run as a systemd service (see setup-spring-service.sh)"
echo "============================================"
