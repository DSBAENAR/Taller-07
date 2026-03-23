# Taller 07 - Secure Application Design on AWS

## Author
David Salomón Baena Rubio

## Overview
A secure, scalable web application deployed on AWS using two EC2 instances: an **Apache HTTP Server** serving an async HTML+JS client over TLS, and a **Spring Boot** backend providing RESTful API endpoints secured with TLS. Both servers use **Let's Encrypt** certificates for encryption.

## Architecture

```
                         HTTPS (TLS)                    HTTPS (TLS)
   Browser  ──────────────────────►  Apache Server  ──────────────────────►  Spring Server
   (Client)                          (EC2 Instance 1)                       (EC2 Instance 2)
                                     Port 443                               Port 8443
                                     taller07-apache.duckdns.org            taller07-spring.duckdns.org
                                     HTML + JS Client                       REST API
                                     Let's Encrypt Cert                     Let's Encrypt Cert
```

### Component Details

| Component | Technology | Port | Purpose |
|-----------|-----------|------|---------|
| **Server 1** | Apache HTTP Server | 443 (HTTPS) | Serves the async HTML+JS client over TLS |
| **Server 2** | Spring Boot 3.2 | 8443 (HTTPS) | REST API with login authentication |
| **Client** | HTML5 + Vanilla JS | - | Async frontend using `fetch()` API |
| **Database** | H2 (in-memory) | - | User storage with BCrypt-hashed passwords |
| **Certificates** | Let's Encrypt | - | TLS certificates for both servers |

### Security Features

1. **TLS Encryption**: All communication encrypted using Let's Encrypt certificates
2. **Password Hashing**: BCrypt algorithm for secure password storage
3. **CORS Protection**: Configured to only allow requests from the Apache server domain
4. **Security Headers**: HSTS, X-Content-Type-Options, X-Frame-Options, X-XSS-Protection
5. **Stateless API**: No server-side session storage (stateless REST)
6. **Input Validation**: Server-side validation on all endpoints

### Request Flow

```
1. User opens https://taller07-apache.duckdns.org
   └─► Apache serves index.html + app.js over HTTPS

2. User registers/logs in
   └─► Browser sends async POST to https://taller07-spring.duckdns.org:8443/api/auth/login
       └─► Spring validates credentials against BCrypt-hashed passwords
           └─► Returns JSON response over HTTPS

3. User interacts with dashboard
   └─► Browser sends async GET to https://taller07-spring.duckdns.org:8443/api/greeting
       └─► Spring processes request and returns JSON over HTTPS
```

## Project Structure

```
Taller-07/
├── apache-client/          # Frontend (Server 1 - Apache)
│   ├── index.html          # Login/Register UI + Dashboard
│   └── app.js              # Async API calls using fetch()
├── spring-backend/         # Backend (Server 2 - Spring Boot)
│   ├── pom.xml             # Maven dependencies
│   └── src/main/java/com/arep/secureapp/
│       ├── SecureAppApplication.java
│       ├── config/
│       │   └── SecurityConfig.java     # BCrypt, CORS, security rules
│       ├── controller/
│       │   ├── AuthController.java     # /api/auth/login, /api/auth/register
│       │   └── GreetingController.java # /api/greeting, /api/health
│       ├── model/
│       │   └── User.java              # JPA entity with hashed password
│       ├── repository/
│       │   └── UserRepository.java    # Spring Data JPA
│       └── service/
│           └── UserService.java       # Authentication + registration logic
└── README.md
```

## API Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/register` | Public | Register new user |
| POST | `/api/auth/login` | Public | Authenticate user |
| GET | `/api/health` | Public | Health check |
| GET | `/api/greeting?name=X` | Protected | Greeting service |

### Request/Response Examples

**Register:**
```json
POST /api/auth/register
{ "username": "daniel", "password": "securePass123" }

Response 201:
{ "message": "User registered successfully", "username": "daniel" }
```

**Login:**
```json
POST /api/auth/login
{ "username": "daniel", "password": "securePass123" }

Response 200:
{ "message": "Login successful", "username": "daniel" }
```

## Deployment on AWS - Step by Step

### Step 1: Create EC2 Instances

Two **t3.micro** instances were created on AWS with **Amazon Linux 2023**:
- **Apache** (3.91.45.135) - serves the frontend client
- **Spring** (3.236.184.212) - runs the backend API

Security Groups:
- `apache-sg`: ports 22 (SSH), 80 (HTTP), 443 (HTTPS)
- `spring-sg`: ports 22 (SSH), 8443 (Custom TCP)

![EC2 Instances Running](imgs/01-ec2-instances.png)

### Step 2: Configure DNS with Duck DNS

Two free subdomains were created at [duckdns.org](https://www.duckdns.org) pointing to each instance:

| Domain | IP |
|--------|-----|
| `taller07-apache.duckdns.org` | 3.91.45.135 |
| `taller07-spring.duckdns.org` | 3.236.184.212 |

### Step 3: Deploy Spring Boot Backend (Server 2)

#### 3.1 Upload project files via SCP

```bash
scp -i "./Taller 7.pem" -r spring-backend ec2-user@3.236.184.212:~/
```

![Uploading Spring files and SSH connection](imgs/Spring/02-scp-upload-spring.png)

#### 3.2 Install Java 17 and Maven

```bash
ssh -i "./Taller 7.pem" ec2-user@3.236.184.212
sudo dnf update -y
sudo dnf install -y java-17-amazon-corretto-devel maven
```

![Installing Java 17 and Maven](imgs/Spring/03-ssh-spring-install-java.png)

![Package list for Java and Maven](imgs/Spring/04-java-maven-packages-list.png)

![Downloading packages](imgs/Spring/05-java-maven-downloading.png)

![Installing packages](imgs/Spring/06-java-maven-installing.png)

![Verifying installation](imgs/Spring/07-java-maven-verifying.png)

#### 3.3 Configure CORS and build

```bash
cd ~/spring-backend
sed -i 's|app.cors.allowed-origins=.*|app.cors.allowed-origins=https://taller07-apache.duckdns.org|' src/main/resources/application.properties
mvn clean package -DskipTests
```

![Maven compile - downloading dependencies](imgs/Spring/08-maven-compile-dependencies.png)

![Maven downloading dependencies](imgs/Spring/09-maven-downloading-deps.png)

![Maven first build success](imgs/Spring/10-maven-build-success.png)

![CORS configuration and mvn package](imgs/Spring/11-maven-package-cors-config.png)

![Maven package build success](imgs/Spring/12-maven-package-success.png)

#### 3.4 Install Certbot and get TLS certificate

```bash
sudo dnf install -y augeas-libs pip
sudo pip install certbot
sudo certbot certonly --standalone -d taller07-spring.duckdns.org
```

![Installing Certbot dependencies](imgs/Spring/14-certbot-install.png)

![Installing Certbot via pip](imgs/Spring/15-certbot-pip-install.png)

![Let's Encrypt certificate obtained successfully](imgs/Spring/16-certbot-certificate-success.png)

#### 3.5 Convert certificate to PKCS12 keystore

Spring Boot requires a PKCS12 keystore. Convert the Let's Encrypt certificate:

```bash
sudo openssl pkcs12 -export -in /etc/letsencrypt/live/taller07-spring.duckdns.org/fullchain.pem -inkey /etc/letsencrypt/live/taller07-spring.duckdns.org/privkey.pem -out /etc/letsencrypt/live/taller07-spring.duckdns.org/keystore.p12 -name tomcat -passout pass:YOUR_PASSWORD
```

Give read permissions so Spring can access the keystore:

```bash
sudo chmod 644 /etc/letsencrypt/live/taller07-spring.duckdns.org/keystore.p12
sudo chmod 755 /etc/letsencrypt/live/ /etc/letsencrypt/archive/
sudo chmod 644 /etc/letsencrypt/archive/taller07-spring.duckdns.org/*
```

![PKCS12 keystore creation and permissions](imgs/Spring/17-pkcs12-keystore-permissions.png)

#### 3.6 Enable TLS in application.properties

```bash
sed -i 's|# server.ssl.enabled=true|server.ssl.enabled=true|' src/main/resources/application.properties
sed -i 's|# server.ssl.key-store=.*|server.ssl.key-store=/etc/letsencrypt/live/taller07-spring.duckdns.org/keystore.p12|' src/main/resources/application.properties
sed -i 's|# server.ssl.key-store-password=.*|server.ssl.key-store-password=YOUR_PASSWORD|' src/main/resources/application.properties
sed -i 's|# server.ssl.key-store-type=.*|server.ssl.key-store-type=PKCS12|' src/main/resources/application.properties
sed -i 's|# server.ssl.key-alias=.*|server.ssl.key-alias=tomcat|' src/main/resources/application.properties
```

![Enabling TLS in application.properties](imgs/Spring/18-sed-enable-tls-properties.png)

#### 3.7 Rebuild and run with HTTPS

```bash
mvn clean package -DskipTests
java -jar target/secure-app-1.0.0.jar
```

![Maven rebuild with TLS enabled](imgs/Spring/19-maven-rebuild-with-tls.png)

The application starts on port 8443 with **HTTPS** enabled via Tomcat.

![Spring Boot application running with HTTPS](imgs/Spring/20-spring-running-https.png)

### Step 4: Deploy Apache Server (Server 1)

#### 4.1 Upload client files from local machine

```bash
scp -i "./Taller 7.pem" apache-client/* ec2-user@3.91.45.135:~/
```

![Uploading client files and SSH to Apache server](imgs/Apache/21-apache-scp-upload-ssh.png)

#### 4.2 Connect and install Apache with SSL

```bash
ssh -i "./Taller 7.pem" ec2-user@3.91.45.135
sudo dnf update -y
sudo dnf install -y httpd mod_ssl
sudo systemctl start httpd
sudo systemctl enable httpd
```

![Installing Apache and mod_ssl](imgs/Apache/22-apache-install-httpd-mod-ssl.png)

![Installation complete](imgs/Apache/23-apache-install-httpd-complete.png)

![Starting and enabling Apache service](imgs/Apache/24-apache-start-enable-httpd.png)

#### 4.3 Deploy client files to web root

```bash
sudo cp ~/index.html ~/app.js /var/www/html/
sudo chown apache:apache /var/www/html/*
```

#### 4.4 Update API URL to point to Spring server

```bash
sudo sed -i 's|https://localhost:8443|https://taller07-spring.duckdns.org:8443|' /var/www/html/app.js
```

#### 4.5 Install Certbot and get TLS certificate

```bash
sudo dnf install -y augeas-libs pip
sudo pip install certbot certbot-apache
sudo certbot --apache -d taller07-apache.duckdns.org
```

![Deploying files and installing pip/certbot dependencies](imgs/Apache/25-apache-deploy-files-install-pip.png)

![Installing certbot dependencies](imgs/Apache/26-apache-install-certbot-deps.png)

![Certbot build errors - installing dev dependencies](imgs/Apache/27-apache-certbot-build-errors.png)

![Installing python3-devel and build dependencies](imgs/Apache/28-apache-install-dev-dependencies.png)

![Dev dependencies installation complete](imgs/Apache/29-apache-install-dev-deps-complete.png)

![Installing augeas-devel](imgs/Apache/30-apache-install-augeas-devel.png)

![Certbot installation success](imgs/Apache/31-apache-certbot-install-success.png)

![Certbot certificate obtained and deployed successfully](imgs/Apache/32-apache-certbot-certificate-success.png)

#### 4.6 Restart Apache

```bash
sudo systemctl restart httpd
```

### Step 5: Application Working

#### 5.1 Register a new user

![Register screen with TLS encrypted connection](imgs/Apache/33-app-register-screen.png)

#### 5.2 Login with credentials

![Login successful](imgs/Apache/34-app-login-success.png)

#### 5.3 Test the Secure API

![Dashboard with greeting response from Spring Boot API](imgs/Apache/35-app-dashboard-greeting.png)

#### 5.4 HTTPS verified in browser

![HTTPS URL in browser address bar](imgs/Apache/36-app-https-url-bar.png)

## Security Implementation Details

### Password Hashing (BCrypt)
Passwords are never stored in plaintext. The `BCryptPasswordEncoder` generates a salted hash:

```java
// Registration: hash the password
String hashedPassword = passwordEncoder.encode(password);

// Login: verify against hash
passwordEncoder.matches(rawPassword, storedHash);
```

### TLS Configuration
- **Apache**: Let's Encrypt + mod_ssl with automatic HTTP to HTTPS redirect
- **Spring Boot**: PKCS12 keystore generated from Let's Encrypt certificates

### CORS
Configured to only accept requests from `https://taller07-apache.duckdns.org`, preventing unauthorized cross-origin requests.

## Technologies
- **Java 17** + **Spring Boot 3.2**
- **Spring Security** (BCrypt, CORS, stateless sessions)
- **Spring Data JPA** + **H2 Database**
- **Apache HTTP Server** + **mod_ssl**
- **Let's Encrypt** (Certbot)
- **AWS EC2** (Amazon Linux 2023)
- **Duck DNS** (free DNS service)
- **HTML5** + **Vanilla JavaScript** (async/await + Fetch API)
