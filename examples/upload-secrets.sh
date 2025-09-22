#!/bin/bash

# Upload Product and Platform Credentials to AWS Secrets Manager
# This script securely uploads the required credentials for the ECS deployment

set -euo pipefail  # Exit on any error, undefined variable, or pipe failure

# Configuration
SECRETS_PREFIX="secure-app/prod"
AWS_REGION="us-west-2"

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

# Function to check if AWS CLI is installed and configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        log_info "Install with: curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip' && unzip awscliv2.zip && sudo ./aws/install"
        exit 1
    fi

    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS CLI is not configured or credentials are invalid."
        log_info "Configure with: aws configure"
        exit 1
    fi

    log_success "AWS CLI is configured and working"
}

# Function to prompt for secret input
prompt_for_secret() {
    local secret_name="$1"
    local prompt_text="$2"
    local secret_value=""
    
    echo
    log_info "$prompt_text"
    echo -n "Enter value: "
    read -s secret_value
    echo
    
    if [[ -z "$secret_value" ]]; then
        log_error "Secret value cannot be empty"
        return 1
    fi
    
    echo "$secret_value"
}

# Function to create or update a secret in AWS Secrets Manager
create_or_update_secret() {
    local secret_name="$1"
    local secret_value="$2"
    
    log_info "Processing secret: $secret_name"
    
    # Check if secret already exists
    if aws secretsmanager describe-secret --secret-id "$secret_name" --region "$AWS_REGION" &> /dev/null; then
        log_warning "Secret '$secret_name' already exists. Updating..."
        
        # Ask for confirmation before updating
        echo -n "Do you want to update this secret? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Skipping update for '$secret_name'"
            return 0
        fi
        
        # Update existing secret
        aws secretsmanager update-secret \
            --secret-id "$secret_name" \
            --secret-string "$secret_value" \
            --region "$AWS_REGION" > /dev/null
        
        log_success "Updated secret: $secret_name"
    else
        # Create new secret
        aws secretsmanager create-secret \
            --name "$secret_name" \
            --description "Managed by upload-secrets.sh script" \
            --secret-string "$secret_value" \
            --region "$AWS_REGION" > /dev/null
        
        log_success "Created secret: $secret_name"
    fi
}

# Function to generate a secure random string
generate_secure_string() {
    local length="${1:-32}"
    openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
}

# Main script
main() {
    echo "============================================"
    echo "AWS Secrets Manager Upload Script"
    echo "============================================"
    echo
    log_info "This script will upload product and platform credentials to AWS Secrets Manager"
    log_info "Secrets will be stored under prefix: $SECRETS_PREFIX"
    log_info "AWS Region: $AWS_REGION"
    echo
    
    # Check AWS CLI
    check_aws_cli
    
    # Confirm before proceeding
    echo -n "Do you want to continue? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled by user"
        exit 0
    fi
    
    echo
    log_info "Please provide the following credentials:"
    echo
    
    # Collect Product Credentials
    log_info "=== Product Credentials ==="
    PRODUCT_CLIENT_ID=$(prompt_for_secret "product_client_id" "Product Client ID")
    PRODUCT_SECRET_KEY=$(prompt_for_secret "product_secret_key" "Product Secret Key")
    
    echo
    log_info "=== Platform Credentials ==="
    PLATFORM_CLIENT_ID=$(prompt_for_secret "platform_client_id" "Platform Client ID") 
    PLATFORM_SECRET_KEY=$(prompt_for_secret "platform_secret_key" "Platform Secret Key")
    
    # Ask if user wants to generate additional secrets
    echo
    log_info "=== Additional Application Secrets ==="
    echo -n "Do you want to generate additional application secrets? (database_url, redis_password, jwt_signing_key, encryption_key) (y/N): "
    read -r generate_additional
    
    # Upload secrets to AWS Secrets Manager
    echo
    log_info "=== Uploading secrets to AWS Secrets Manager ==="
    
    create_or_update_secret "$SECRETS_PREFIX/product_client_id" "$PRODUCT_CLIENT_ID"
    create_or_update_secret "$SECRETS_PREFIX/product_secret_key" "$PRODUCT_SECRET_KEY"
    create_or_update_secret "$SECRETS_PREFIX/platform_client_id" "$PLATFORM_CLIENT_ID"
    create_or_update_secret "$SECRETS_PREFIX/platform_secret_key" "$PLATFORM_SECRET_KEY"
    
    # Generate and upload additional secrets if requested
    if [[ "$generate_additional" =~ ^[Yy]$ ]]; then
        log_info "Generating additional application secrets..."
        
        # Generate database URL (placeholder - user should update)
        DB_URL="postgresql://app_user:$(generate_secure_string 16)@localhost:5432/secure_app_db"
        create_or_update_secret "$SECRETS_PREFIX/database_url" "$DB_URL"
        
        # Generate Redis password
        REDIS_PASS=$(generate_secure_string 24)
        create_or_update_secret "$SECRETS_PREFIX/redis_password" "$REDIS_PASS"
        
        # Generate JWT signing key
        JWT_KEY=$(generate_secure_string 64)
        create_or_update_secret "$SECRETS_PREFIX/jwt_signing_key" "$JWT_KEY"
        
        # Generate encryption key
        ENCRYPT_KEY=$(generate_secure_string 32)
        create_or_update_secret "$SECRETS_PREFIX/encryption_key" "$ENCRYPT_KEY"
        
        log_warning "Note: The generated database_url is a placeholder. Please update it with your actual database connection string."
    fi
    
    echo
    log_success "All secrets have been uploaded successfully!"
    echo
    log_info "=== Next Steps ==="
    log_info "1. Run ./create-keypair.sh to generate EC2 keypair"
    log_info "2. Run ./generate-certs.sh to generate and upload TLS certificates"
    log_info "3. Update terraform.tfvars with your VPC and subnet IDs"
    log_info "4. Run terraform apply to deploy your infrastructure"
    echo
    log_info "=== Secrets Created ==="
    log_info "• $SECRETS_PREFIX/product_client_id"
    log_info "• $SECRETS_PREFIX/product_secret_key"
    log_info "• $SECRETS_PREFIX/platform_client_id"
    log_info "• $SECRETS_PREFIX/platform_secret_key"
    
    if [[ "$generate_additional" =~ ^[Yy]$ ]]; then
        log_info "• $SECRETS_PREFIX/database_url"
        log_info "• $SECRETS_PREFIX/redis_password"
        log_info "• $SECRETS_PREFIX/jwt_signing_key"
        log_info "• $SECRETS_PREFIX/encryption_key"
    fi
    
    echo
    log_warning "SECURITY REMINDER: These credentials are now stored in AWS Secrets Manager."
    log_warning "Make sure to configure proper IAM permissions for your ECS tasks to access these secrets."
    echo
}

# Handle script interruption
trap 'log_error "Script interrupted by user"; exit 1' INT TERM

# Run main function
main "$@"