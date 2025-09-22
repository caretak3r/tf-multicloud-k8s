#!/bin/bash

# generate-certificates.sh
# Script to generate self-signed SSL certificates for ECS HTTP server
# This script creates certificates that will be mounted to the container

set -euo pipefail

# Configuration
DOMAIN_NAME="http-server.example.local"
CERT_DIR="./certs"
KEY_SIZE=2048
DAYS=365

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if OpenSSL is installed
check_openssl() {
    if ! command -v openssl &> /dev/null; then
        log_error "OpenSSL is not installed. Please install it first."
        log_info "On macOS: brew install openssl"
        log_info "On Ubuntu/Debian: sudo apt-get install openssl"
        log_info "On RHEL/CentOS: sudo yum install openssl"
        exit 1
    fi
    
    log_success "OpenSSL found: $(openssl version)"
}

# Create certificate directory
create_cert_directory() {
    if [ -d "$CERT_DIR" ]; then
        log_warning "Certificate directory already exists: $CERT_DIR"
        read -p "Do you want to overwrite existing certificates? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Exiting without generating certificates."
            exit 0
        fi
        rm -rf "$CERT_DIR"
    fi
    
    mkdir -p "$CERT_DIR"
    log_success "Created certificate directory: $CERT_DIR"
}

# Generate private key
generate_private_key() {
    log_info "Generating private key..."
    
    openssl genrsa -out "$CERT_DIR/server.key" $KEY_SIZE
    chmod 600 "$CERT_DIR/server.key"
    
    log_success "Private key generated: $CERT_DIR/server.key"
}

# Generate certificate signing request
generate_csr() {
    log_info "Generating certificate signing request..."
    
    # Create a config file for the CSR to include Subject Alternative Names
    cat > "$CERT_DIR/csr.conf" <<EOF
[req]
default_bits = $KEY_SIZE
prompt = no
distinguished_name = dn
req_extensions = v3_req

[dn]
C = US
ST = California
L = San Francisco
O = Development
OU = Engineering
CN = $DOMAIN_NAME

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN_NAME
DNS.2 = localhost
DNS.3 = *.example.local
IP.1 = 127.0.0.1
IP.2 = 10.0.0.0
EOF

    openssl req -new -key "$CERT_DIR/server.key" -out "$CERT_DIR/server.csr" -config "$CERT_DIR/csr.conf"
    
    log_success "Certificate signing request generated: $CERT_DIR/server.csr"
}

# Generate self-signed certificate
generate_certificate() {
    log_info "Generating self-signed certificate..."
    
    # Create certificate extensions file
    cat > "$CERT_DIR/cert.conf" <<EOF
[req]
default_bits = $KEY_SIZE
prompt = no
distinguished_name = dn
req_extensions = v3_req

[dn]
C = US
ST = California
L = San Francisco
O = Development
OU = Engineering
CN = $DOMAIN_NAME

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
extendedKeyUsage = serverAuth

[alt_names]
DNS.1 = $DOMAIN_NAME
DNS.2 = localhost
DNS.3 = *.example.local
IP.1 = 127.0.0.1
IP.2 = 10.0.0.0
EOF

    openssl x509 -req -in "$CERT_DIR/server.csr" \
        -signkey "$CERT_DIR/server.key" \
        -out "$CERT_DIR/server.crt" \
        -days $DAYS \
        -extensions v3_req \
        -extfile "$CERT_DIR/cert.conf"
    
    log_success "Self-signed certificate generated: $CERT_DIR/server.crt"
}

# Create certificate bundle
create_certificate_bundle() {
    log_info "Creating certificate bundle..."
    
    # Create a bundle with cert and key for easy deployment
    cat "$CERT_DIR/server.crt" "$CERT_DIR/server.key" > "$CERT_DIR/server-bundle.pem"
    
    # Create PEM files for different use cases
    cp "$CERT_DIR/server.crt" "$CERT_DIR/server.pem"
    
    log_success "Certificate bundle created: $CERT_DIR/server-bundle.pem"
}

# Generate CA certificate (for client trust)
generate_ca_certificate() {
    log_info "Generating CA certificate for client trust..."
    
    # Generate CA private key
    openssl genrsa -out "$CERT_DIR/ca.key" $KEY_SIZE
    chmod 600 "$CERT_DIR/ca.key"
    
    # Generate CA certificate
    openssl req -x509 -new -nodes -key "$CERT_DIR/ca.key" -sha256 -days $DAYS \
        -out "$CERT_DIR/ca.crt" -subj "/C=US/ST=CA/L=SF/O=Dev/OU=Engineering/CN=DevCA"
    
    log_success "CA certificate generated: $CERT_DIR/ca.crt"
    log_info "Install ca.crt in your browser/system to trust the certificates"
}

# Set appropriate permissions
set_permissions() {
    log_info "Setting appropriate file permissions..."
    
    # Private keys should be readable only by owner
    chmod 600 "$CERT_DIR"/*.key 2>/dev/null || true
    
    # Certificates can be readable by group
    chmod 644 "$CERT_DIR"/*.crt "$CERT_DIR"/*.pem 2>/dev/null || true
    
    log_success "File permissions set correctly"
}

# Verify certificates
verify_certificates() {
    log_info "Verifying generated certificates..."
    
    # Verify certificate
    if openssl x509 -in "$CERT_DIR/server.crt" -text -noout > /dev/null 2>&1; then
        log_success "Certificate is valid"
        
        # Show certificate details
        echo -e "\n${BLUE}Certificate Details:${NC}"
        openssl x509 -in "$CERT_DIR/server.crt" -text -noout | grep -A1 "Subject:"
        openssl x509 -in "$CERT_DIR/server.crt" -text -noout | grep -A5 "Subject Alternative Name:"
        openssl x509 -in "$CERT_DIR/server.crt" -text -noout | grep -A2 "Validity"
    else
        log_error "Generated certificate is invalid"
        exit 1
    fi
    
    # Verify private key
    if openssl rsa -in "$CERT_DIR/server.key" -check -noout > /dev/null 2>&1; then
        log_success "Private key is valid"
    else
        log_error "Generated private key is invalid"
        exit 1
    fi
    
    # Verify key-certificate pair
    cert_modulus=$(openssl x509 -noout -modulus -in "$CERT_DIR/server.crt" | openssl md5)
    key_modulus=$(openssl rsa -noout -modulus -in "$CERT_DIR/server.key" | openssl md5)
    
    if [ "$cert_modulus" = "$key_modulus" ]; then
        log_success "Certificate and private key match"
    else
        log_error "Certificate and private key do not match"
        exit 1
    fi
}

# Create nginx configuration template
create_nginx_config() {
    log_info "Creating nginx configuration template..."
    
    cat > "$CERT_DIR/nginx.conf" <<EOF
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    # Logging
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log warn;
    
    # Basic settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Upstream for secrets sidecar
    upstream secrets_sidecar {
        server localhost:8080;
    }
    
    # HTTPS server
    server {
        listen 443 ssl http2;
        server_name $DOMAIN_NAME localhost;
        
        # SSL configuration
        ssl_certificate /etc/ssl/certs/server.crt;
        ssl_certificate_key /etc/ssl/private/server.key;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;
        
        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
        
        # Proxy to secrets sidecar (internal only)
        location /internal/secrets/ {
            internal;
            proxy_pass http://secrets_sidecar/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
        }
        
        # Main application
        location / {
            root /usr/share/nginx/html;
            index index.html;
            
            # Example: Add secrets to headers (for demo purposes)
            # In production, secrets should be used by the application, not exposed in headers
            set \$db_password "";
            set \$api_key "";
            
            # Uncomment these lines to fetch secrets from sidecar
            # access_by_lua_block {
            #     local http = require "resty.http"
            #     local httpc = http.new()
            #     local res, err = httpc:request_uri("http://localhost:8080/secrets/database_password")
            #     if res and res.body then
            #         ngx.var.db_password = res.body
            #     end
            # }
        }
        
        # Error pages
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root /usr/share/nginx/html;
        }
    }
    
    # Redirect HTTP to HTTPS
    server {
        listen 80;
        server_name $DOMAIN_NAME localhost;
        return 301 https://\$server_name\$request_uri;
    }
}
EOF
    
    log_success "Nginx configuration template created: $CERT_DIR/nginx.conf"
}

# Create Dockerfile template
create_dockerfile() {
    log_info "Creating Dockerfile template..."
    
    cat > "$CERT_DIR/Dockerfile.http-server" <<EOF
# Multi-stage build for HTTP server with self-signed certificates
FROM nginx:alpine

# Install required packages
RUN apk add --no-cache curl openssl

# Create SSL directories
RUN mkdir -p /etc/ssl/certs /etc/ssl/private

# Copy SSL certificates
COPY certs/server.crt /etc/ssl/certs/
COPY certs/server.key /etc/ssl/private/
COPY certs/nginx.conf /etc/nginx/nginx.conf

# Set appropriate permissions
RUN chmod 644 /etc/ssl/certs/server.crt && \
    chmod 600 /etc/ssl/private/server.key && \
    chown root:root /etc/ssl/certs/server.crt /etc/ssl/private/server.key

# Create a simple index page
RUN echo '<h1>HTTP Server with Secrets Sidecar</h1><p>Server is running with HTTPS and secrets integration.</p>' > /usr/share/nginx/html/index.html

# Expose HTTPS port
EXPOSE 443

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -k -f https://localhost/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
EOF
    
    log_success "Dockerfile template created: $CERT_DIR/Dockerfile.http-server"
}

# Create AWS import script
create_aws_import_script() {
    log_info "Creating AWS certificate import script..."
    
    cat > "$CERT_DIR/import-to-acm.sh" <<EOF
#!/bin/bash

# import-to-acm.sh
# Script to import self-signed certificate to AWS Certificate Manager

set -euo pipefail

CERT_FILE="./server.crt"
KEY_FILE="./server.key"
REGION="us-west-2"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if certificate files exist
if [[ ! -f "\$CERT_FILE" ]] || [[ ! -f "\$KEY_FILE" ]]; then
    echo "Certificate files not found. Please run generate-certificates.sh first."
    exit 1
fi

# Import certificate to ACM
echo "Importing certificate to AWS Certificate Manager..."

CERT_ARN=\$(aws acm import-certificate \
    --certificate fileb://\$CERT_FILE \
    --private-key fileb://\$KEY_FILE \
    --region \$REGION \
    --query 'CertificateArn' \
    --output text)

echo "Certificate imported successfully!"
echo "Certificate ARN: \$CERT_ARN"
echo ""
echo "You can now use this certificate ARN in your Terraform configuration:"
echo "ecs_acm_certificate_arn = \"\$CERT_ARN\""
EOF
    
    chmod +x "$CERT_DIR/import-to-acm.sh"
    log_success "AWS import script created: $CERT_DIR/import-to-acm.sh"
}

# Print summary
print_summary() {
    echo -e "\n${GREEN}=================== CERTIFICATE GENERATION COMPLETE ===================${NC}"
    echo -e "\n${BLUE}Generated Files:${NC}"
    echo "📁 Certificate directory: $CERT_DIR"
    echo "🔐 Private key: $CERT_DIR/server.key"
    echo "📜 Certificate: $CERT_DIR/server.crt"
    echo "📦 Bundle: $CERT_DIR/server-bundle.pem"
    echo "🏛️  CA certificate: $CERT_DIR/ca.crt"
    echo "⚙️  Nginx config: $CERT_DIR/nginx.conf"
    echo "🐳 Dockerfile: $CERT_DIR/Dockerfile.http-server"
    echo "☁️  AWS import script: $CERT_DIR/import-to-acm.sh"
    
    echo -e "\n${BLUE}Next Steps:${NC}"
    echo "1. 📋 Review certificate details above"
    echo "2. 🚀 Use certificates in your ECS deployment"
    echo "3. 🔧 Customize nginx.conf for your application"
    echo "4. 🐳 Build Docker image using the Dockerfile template"
    echo "5. ☁️  Import to ACM: cd $CERT_DIR && ./import-to-acm.sh"
    
    echo -e "\n${YELLOW}Security Notes:${NC}"
    echo "⚠️  Self-signed certificates are for development/testing only"
    echo "🔒 Private key permissions are set to 600 (owner read only)"
    echo "🏢 For production, use certificates from a trusted CA"
    echo "🔄 Consider setting up certificate rotation"
    
    echo -e "\n${BLUE}Certificate Details:${NC}"
    echo "🌐 Domain: $DOMAIN_NAME"
    echo "📅 Valid for: $DAYS days"
    echo "🔑 Key size: $KEY_SIZE bits"
    echo "✅ Includes Subject Alternative Names for flexibility"
    
    echo -e "\n${GREEN}Certificate generation completed successfully!${NC}"
}

# Main execution
main() {
    echo -e "${GREEN}=================== SSL CERTIFICATE GENERATOR ===================${NC}"
    echo -e "${BLUE}Generating self-signed SSL certificates for ECS HTTP server${NC}"
    echo -e "${BLUE}Domain: $DOMAIN_NAME${NC}"
    echo -e "${BLUE}Certificate directory: $CERT_DIR${NC}\n"
    
    check_openssl
    create_cert_directory
    generate_private_key
    generate_csr
    generate_certificate
    create_certificate_bundle
    generate_ca_certificate
    set_permissions
    verify_certificates
    create_nginx_config
    create_dockerfile
    create_aws_import_script
    print_summary
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--domain)
            DOMAIN_NAME="$2"
            shift 2
            ;;
        -o|--output)
            CERT_DIR="$2"
            shift 2
            ;;
        -k|--key-size)
            KEY_SIZE="$2"
            shift 2
            ;;
        --days)
            DAYS="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Generate self-signed SSL certificates for ECS HTTP server"
            echo ""
            echo "Options:"
            echo "  -d, --domain DOMAIN     Domain name for the certificate (default: http-server.example.local)"
            echo "  -o, --output DIR        Output directory for certificates (default: ./certs)"
            echo "  -k, --key-size SIZE     RSA key size in bits (default: 2048)"
            echo "      --days DAYS         Certificate validity in days (default: 365)"
            echo "  -h, --help              Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Use defaults"
            echo "  $0 -d myapp.local -o ./ssl           # Custom domain and output directory"
            echo "  $0 -k 4096 --days 730                # 4096-bit key, valid for 2 years"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Run main function
main