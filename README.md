# Taller 07 - Secure Application Design on AWS

## Author
David Salomón Baena Rubio

## Overview
A secure, scalable web application deployed on AWS using two EC2 instances: an **Apache HTTP Server** serving an async HTML+JS client over TLS, and a **Spring Boot** backend providing RESTful API endpoints secured with TLS. Both servers use **Let's Encrypt** certificates for encryption.

## Architecture

```
                         HTTPS (TLS)                    HTTPS (TLS)
   Browser  ──────────────────────►  Apache Server  ──────────────────►  Spring Server
   (Client)                          (EC2 Instance 1)                   (EC2 Instance 2)
                                     Port 443                           Port 8443
                                     HTML + JS Client                   REST API
                                     Let's Encrypt Cert                 Let's Encrypt Cert
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
1. User opens https://apache-domain.com
   └─► Apache serves index.html + app.js over HTTPS

2. User registers/logs in
   └─► Browser sends async POST to https://spring-domain.com:8443/api/auth/login
       └─► Spring validates credentials against BCrypt-hashed passwords
           └─► Returns JSON response over HTTPS

3. User interacts with dashboard
   └─► Browser sends async GET to https://spring-domain.com:8443/api/greeting
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
├── scripts/                # Deployment scripts
│   ├── setup-apache-server.sh   # Apache + Let's Encrypt setup
│   ├── setup-spring-server.sh   # Java + Maven + Certbot setup
│   ├── setup-spring-service.sh  # systemd service for Spring
│   └── apache-vhost.conf        # Apache virtual host config
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

## Deployment on AWS

### Prerequisites
- 2 AWS EC2 instances (Amazon Linux 2023 recommended)
- 2 domain names (or subdomains) pointing to each instance
- Security groups allowing ports: 22 (SSH), 80/443 (Apache), 8443 (Spring)

### Server 1: Apache Setup

```bash
# SSH into the Apache EC2 instance
ssh -i your-key.pem ec2-user@apache-instance-ip

# Upload client files
scp -i your-key.pem -r apache-client/* ec2-user@apache-instance-ip:~/apache-client/

# Run setup script
scp -i your-key.pem scripts/setup-apache-server.sh ec2-user@apache-instance-ip:~/
ssh -i your-key.pem ec2-user@apache-instance-ip 'bash ~/setup-apache-server.sh'

# Get TLS certificate
sudo certbot --apache -d your-apache-domain.com

# Update app.js with Spring server URL
sudo vi /var/www/html/app.js
# Change API_BASE_URL to: https://your-spring-domain.com:8443
```

### Server 2: Spring Boot Setup

```bash
# SSH into the Spring EC2 instance
ssh -i your-key.pem ec2-user@spring-instance-ip

# Upload backend code
scp -i your-key.pem -r spring-backend ec2-user@spring-instance-ip:~/

# Run setup script
scp -i your-key.pem scripts/setup-spring-server.sh ec2-user@spring-instance-ip:~/
ssh -i your-key.pem ec2-user@spring-instance-ip 'bash ~/setup-spring-server.sh your-spring-domain.com'

# Get TLS certificate
sudo certbot certonly --standalone -d your-spring-domain.com

# Convert to PKCS12 for Spring Boot
sudo openssl pkcs12 -export \
  -in /etc/letsencrypt/live/your-spring-domain.com/fullchain.pem \
  -inkey /etc/letsencrypt/live/your-spring-domain.com/privkey.pem \
  -out /etc/letsencrypt/live/your-spring-domain.com/keystore.p12 \
  -name tomcat -password pass:changeit

# Update application.properties - uncomment TLS lines and set paths
vi spring-backend/src/main/resources/application.properties

# Rebuild and run
cd spring-backend && mvn clean package -DskipTests
java -jar target/secure-app-1.0.0.jar
```

### Local Testing (without AWS)

```bash
# Terminal 1: Run Spring Boot backend
cd spring-backend
mvn spring-boot:run

# Open apache-client/index.html in browser
# Or use Python's HTTP server:
cd apache-client
python3 -m http.server 8080
# Visit http://localhost:8080
```

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
- **Apache**: Let's Encrypt + mod_ssl with automatic HTTP→HTTPS redirect
- **Spring Boot**: PKCS12 keystore from Let's Encrypt certificates

### CORS
Configured to only accept requests from the Apache server's domain, preventing unauthorized cross-origin requests.

## Technologies
- **Java 17** + **Spring Boot 3.2**
- **Spring Security** (BCrypt, CORS, stateless sessions)
- **Spring Data JPA** + **H2 Database**
- **Apache HTTP Server** + **mod_ssl**
- **Let's Encrypt** (Certbot)
- **AWS EC2** (Amazon Linux 2023)
- **HTML5** + **Vanilla JavaScript** (async/await + Fetch API)

## Screenshots
*(Add screenshots from your AWS deployment here)*
- Login page over HTTPS
- Registration flow
- Dashboard with API response
- Browser TLS certificate details
- AWS EC2 instances
