#!/bin/bash

# Generate SSL Certificates and Upload to AWS Secrets Manager
# This script creates SSL certificates for inter-container TLS communication
# and optionally for load balancer usage if ACM certificate is not provided

set -euo pipefail  # Exit on any error, undefined variable, or pipe failure

# Configuration
SECRETS_PREFIX="secure-app/prod"
AWS_REGION="us-west-2"
CERT_VALIDITY_DAYS=365
KEY_SIZE=4096

# Certificate file names
PRIVATE_KEY_FILE="ssl_certificate.key"
CERTIFICATE_FILE="ssl_certificate.pem"
CSR_FILE="ssl_certificate.csr"
CONFIG_FILE="ssl_certificate.conf"

# Default certificate settings
DEFAULT_COUNTRY="US"
DEFAULT_STATE="California"
DEFAULT_CITY="San Francisco"
DEFAULT_ORGANIZATION="Secure App Corp"
DEFAULT_OU="IT Department"
DEFAULT_COMMON_NAME="secure-app.local"
DEFAULT_EMAIL="admin@secure-app.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
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

# Function to check if required tools are installed
check_dependencies() {
    local missing_tools=()
    
    if ! command -v openssl &> /dev/null; then
        missing_tools+=("openssl")
    fi
    
    if ! command -v aws &> /dev/null; then
        missing_tools+=("aws-cli")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install the missing tools and run this script again"
        exit 1
    fi
    
    log_success "All required tools are available"
}

# Function to check AWS CLI configuration
check_aws_cli() {
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS CLI is not configured or credentials are invalid"
        log_info "Configure with: aws configure"
        exit 1
    fi
    
    log_success "AWS CLI is configured and working"
}

# Function to collect certificate information
collect_cert_info() {
    echo
    log_info "=== SSL Certificate Configuration ==="
    echo "Please provide certificate information (press Enter for defaults):"
    echo
    
    echo -n "Country (2-letter code) [$DEFAULT_COUNTRY]: "
    read -r COUNTRY
    COUNTRY=${COUNTRY:-$DEFAULT_COUNTRY}
    
    echo -n "State/Province [$DEFAULT_STATE]: "
    read -r STATE
    STATE=${STATE:-$DEFAULT_STATE}
    
    echo -n "City [$DEFAULT_CITY]: "
    read -r CITY
    CITY=${CITY:-$DEFAULT_CITY}
    
    echo -n "Organization [$DEFAULT_ORGANIZATION]: "
    read -r ORGANIZATION
    ORGANIZATION=${ORGANIZATION:-$DEFAULT_ORGANIZATION}
    
    echo -n "Organizational Unit [$DEFAULT_OU]: "
    read -r OU
    OU=${OU:-$DEFAULT_OU}
    
    echo -n "Common Name (domain) [$DEFAULT_COMMON_NAME]: "
    read -r COMMON_NAME
    COMMON_NAME=${COMMON_NAME:-$DEFAULT_COMMON_NAME}
    
    echo -n "Email Address [$DEFAULT_EMAIL]: "
    read -r EMAIL
    EMAIL=${EMAIL:-$DEFAULT_EMAIL}
    
    echo
    log_info "Certificate will be created with:"
    log_info "  Country: $COUNTRY"
    log_info "  State: $STATE"
    log_info "  City: $CITY"
    log_info "  Organization: $ORGANIZATION"
    log_info "  Organizational Unit: $OU"
    log_info "  Common Name: $COMMON_NAME"
    log_info "  Email: $EMAIL"
    log_info "  Validity: $CERT_VALIDITY_DAYS days"
    log_info "  Key Size: $KEY_SIZE bits"
}

# Function to create OpenSSL configuration file
create_ssl_config() {
    log_info "Creating OpenSSL configuration file..."
    
    cat > "$CONFIG_FILE" << EOF
[req]
default_bits = $KEY_SIZE
prompt = no
distinguished_name = req_distinguished_name
req_extensions = v3_req
x509_extensions = v3_ca

[req_distinguished_name]
C = $COUNTRY
ST = $STATE
L = $CITY
O = $ORGANIZATION
OU = $OU
CN = $COMMON_NAME
emailAddress = $EMAIL

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
extendedKeyUsage = serverAuth, clientAuth

[v3_ca]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical,CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
subjectAltName = @alt_names
extendedKeyUsage = serverAuth, clientAuth

[alt_names]
DNS.1 = $COMMON_NAME
DNS.2 = localhost
DNS.3 = *.local
DNS.4 = secure-app
DNS.5 = *.secure-app.local
IP.1 = 127.0.0.1
IP.2 = 10.0.0.0/8
IP.3 = 172.16.0.0/12
IP.4 = 192.168.0.0/16
EOF

    log_success "OpenSSL configuration created: $CONFIG_FILE"
}

# Function to generate private key
generate_private_key() {
    log_info "Generating $KEY_SIZE-bit RSA private key..."
    
    openssl genrsa -out "$PRIVATE_KEY_FILE" $KEY_SIZE
    chmod 600 "$PRIVATE_KEY_FILE"
    
    log_success "Private key generated: $PRIVATE_KEY_FILE"
}

# Function to generate certificate signing request
generate_csr() {
    log_info "Generating Certificate Signing Request..."
    
    openssl req -new \
        -key "$PRIVATE_KEY_FILE" \
        -out "$CSR_FILE" \
        -config "$CONFIG_FILE"
    
    log_success "CSR generated: $CSR_FILE"
}

# Function to generate self-signed certificate
generate_certificate() {
    log_info "Generating self-signed certificate..."
    
    openssl req -x509 \
        -new \
        -key "$PRIVATE_KEY_FILE" \
        -out "$CERTIFICATE_FILE" \
        -days $CERT_VALIDITY_DAYS \
        -config "$CONFIG_FILE" \
        -extensions v3_ca
    
    chmod 644 "$CERTIFICATE_FILE"
    
    log_success "Self-signed certificate generated: $CERTIFICATE_FILE"
}

# Function to validate certificate
validate_certificate() {
    log_info "Validating generated certificate..."
    
    # Check certificate validity
    if ! openssl x509 -in "$CERTIFICATE_FILE" -text -noout > /dev/null 2>&1; then
        log_error "Certificate validation failed"
        return 1
    fi
    
    # Check if private key matches certificate
    local cert_modulus key_modulus
    cert_modulus=$(openssl x509 -noout -modulus -in "$CERTIFICATE_FILE" | openssl md5)
    key_modulus=$(openssl rsa -noout -modulus -in "$PRIVATE_KEY_FILE" | openssl md5)
    
    if [[ "$cert_modulus" != "$key_modulus" ]]; then
        log_error "Private key does not match certificate"
        return 1
    fi
    
    log_success "Certificate validation passed"
}

# Function to display certificate information
display_cert_info() {
    echo
    log_info "=== Certificate Information ==="
    
    # Display certificate details
    openssl x509 -in "$CERTIFICATE_FILE" -text -noout | grep -A 1 "Subject:"
    openssl x509 -in "$CERTIFICATE_FILE" -text -noout | grep -A 1 "Validity"
    openssl x509 -in "$CERTIFICATE_FILE" -text -noout | grep -A 10 "Subject Alternative Name"
    
    # Display certificate fingerprints
    echo
    log_info "Certificate Fingerprints:"
    local sha256_fp sha1_fp
    sha256_fp=$(openssl x509 -noout -fingerprint -sha256 -in "$CERTIFICATE_FILE" | cut -d'=' -f2)
    sha1_fp=$(openssl x509 -noout -fingerprint -sha1 -in "$CERTIFICATE_FILE" | cut -d'=' -f2)
    log_info "  SHA256: $sha256_fp"
    log_info "  SHA1:   $sha1_fp"
}

# Function to upload certificates to AWS Secrets Manager
upload_to_secrets_manager() {
    log_info "Uploading certificates to AWS Secrets Manager..."
    
    # Read certificate and private key content
    local cert_content key_content
    cert_content=$(cat "$CERTIFICATE_FILE")
    key_content=$(cat "$PRIVATE_KEY_FILE")
    
    # Upload certificate
    local cert_secret_name="$SECRETS_PREFIX/ssl_certificate"
    if aws secretsmanager describe-secret --secret-id "$cert_secret_name" --region "$AWS_REGION" &> /dev/null; then
        log_warning "Certificate secret already exists. Updating..."
        aws secretsmanager update-secret \
            --secret-id "$cert_secret_name" \
            --secret-string "$cert_content" \
            --region "$AWS_REGION" > /dev/null
    else
        aws secretsmanager create-secret \
            --name "$cert_secret_name" \
            --description "SSL certificate for secure-app (generated by generate-certs.sh)" \
            --secret-string "$cert_content" \
            --region "$AWS_REGION" > /dev/null
    fi
    log_success "Certificate uploaded to: $cert_secret_name"
    
    # Upload private key
    local key_secret_name="$SECRETS_PREFIX/ssl_private_key"
    if aws secretsmanager describe-secret --secret-id "$key_secret_name" --region "$AWS_REGION" &> /dev/null; then
        log_warning "Private key secret already exists. Updating..."
        aws secretsmanager update-secret \
            --secret-id "$key_secret_name" \
            --secret-string "$key_content" \
            --region "$AWS_REGION" > /dev/null
    else
        aws secretsmanager create-secret \
            --name "$key_secret_name" \
            --description "SSL private key for secure-app (generated by generate-certs.sh)" \
            --secret-string "$key_content" \
            --region "$AWS_REGION" > /dev/null
    fi
    log_success "Private key uploaded to: $key_secret_name"
}

# Function to create certificate bundle
create_certificate_bundle() {
    local bundle_file="ssl_certificate_bundle.pem"
    
    log_info "Creating certificate bundle..."
    
    # Combine certificate and private key into a single file
    cat "$CERTIFICATE_FILE" "$PRIVATE_KEY_FILE" > "$bundle_file"
    chmod 600 "$bundle_file"
    
    log_success "Certificate bundle created: $bundle_file"
    
    # Upload bundle to secrets manager
    local bundle_secret_name="$SECRETS_PREFIX/ssl_certificate_bundle"
    local bundle_content
    bundle_content=$(cat "$bundle_file")
    
    if aws secretsmanager describe-secret --secret-id "$bundle_secret_name" --region "$AWS_REGION" &> /dev/null; then
        aws secretsmanager update-secret \
            --secret-id "$bundle_secret_name" \
            --secret-string "$bundle_content" \
            --region "$AWS_REGION" > /dev/null
    else
        aws secretsmanager create-secret \
            --name "$bundle_secret_name" \
            --description "SSL certificate bundle for secure-app (generated by generate-certs.sh)" \
            --secret-string "$bundle_content" \
            --region "$AWS_REGION" > /dev/null
    fi
    
    log_success "Certificate bundle uploaded to: $bundle_secret_name"
}

# Function to cleanup temporary files
cleanup_files() {
    echo -n "Do you want to keep the local certificate files? (Y/n): "
    read -r response
    
    if [[ "$response" =~ ^[Nn]$ ]]; then
        rm -f "$PRIVATE_KEY_FILE" "$CERTIFICATE_FILE" "$CSR_FILE" "$CONFIG_FILE" "ssl_certificate_bundle.pem"
        log_success "Local certificate files cleaned up"
    else
        log_info "Local certificate files preserved"
        log_warning "Remember to store these files securely and never commit them to version control"
    fi
}

# Main script
main() {
    echo "============================================"
    echo "SSL Certificate Generation Script"
    echo "============================================"
    echo
    log_info "This script will generate SSL certificates for inter-container TLS communication"
    log_info "Certificates will be uploaded to AWS Secrets Manager under: $SECRETS_PREFIX/"
    log_info "AWS Region: $AWS_REGION"
    echo
    
    # Check dependencies and AWS configuration
    check_dependencies
    check_aws_cli
    
    # Check if certificate files already exist
    if [[ -f "$CERTIFICATE_FILE" ]] || [[ -f "$PRIVATE_KEY_FILE" ]]; then
        log_warning "Certificate files already exist in current directory"
        echo -n "Do you want to overwrite them? (y/N): "
        read -r response
        
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Operation cancelled by user"
            exit 0
        fi
        
        rm -f "$PRIVATE_KEY_FILE" "$CERTIFICATE_FILE" "$CSR_FILE" "$CONFIG_FILE"
    fi
    
    # Collect certificate information
    collect_cert_info
    
    # Confirm before proceeding
    echo -n "Do you want to continue with certificate generation? (Y/n): "
    read -r response
    if [[ "$response" =~ ^[Nn]$ ]]; then
        log_info "Operation cancelled by user"
        exit 0
    fi
    
    echo
    log_info "=== Generating SSL Certificate ==="
    
    # Generate certificate components
    create_ssl_config
    generate_private_key
    generate_csr
    generate_certificate
    
    # Validate certificate
    validate_certificate
    
    # Display certificate information
    display_cert_info
    
    # Upload to AWS Secrets Manager
    upload_to_secrets_manager
    
    # Create certificate bundle
    create_certificate_bundle
    
    # Success message
    echo
    log_success "SSL certificate generation and upload completed successfully!"
    echo
    log_info "=== Certificates Created in AWS Secrets Manager ==="
    log_info "• $SECRETS_PREFIX/ssl_certificate"
    log_info "• $SECRETS_PREFIX/ssl_private_key"
    log_info "• $SECRETS_PREFIX/ssl_certificate_bundle"
    echo
    log_info "=== Certificate Usage ==="
    log_info "These certificates can be used for:"
    log_info "• Inter-container TLS communication"
    log_info "• Load balancer SSL termination (if ACM certificate not available)"
    log_info "• Service-to-service authentication"
    echo
    log_warning "=== Security Notes ==="
    log_warning "• These are self-signed certificates - not suitable for public internet"
    log_warning "• For production, consider using ACM certificates or CA-signed certificates"
    log_warning "• Certificate expires in $CERT_VALIDITY_DAYS days"
    log_warning "• Set up certificate rotation before expiry"
    echo
    log_info "=== Next Steps ==="
    log_info "1. Update terraform.tfvars to reference these certificate secrets"
    log_info "2. Run terraform apply to deploy your infrastructure"
    log_info "3. Your ECS services will automatically have access to these certificates"
    echo
    
    # Cleanup
    cleanup_files
}

# Handle script interruption
trap 'log_error "Script interrupted by user"; exit 1' INT TERM

# Run main function
main "$@"