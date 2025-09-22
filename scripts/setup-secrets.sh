#!/bin/bash

# setup-secrets.sh
# Script to create dummy secrets in AWS Secrets Manager for ECS HTTP server
# This script creates secrets that the sidecar container will fetch

set -euo pipefail

# Configuration
REGION="us-west-2"
SECRET_PREFIX="http-server/"
ENVIRONMENT="development"

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

# Check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        log_info "Installation instructions:"
        log_info "  macOS: brew install awscli"
        log_info "  Linux: pip install awscli"
        log_info "  Windows: Download from https://aws.amazon.com/cli/"
        exit 1
    fi
    
    log_success "AWS CLI found: $(aws --version)"
}

# Check AWS credentials
check_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured or invalid."
        log_info "Configure credentials using one of:"
        log_info "  aws configure"
        log_info "  export AWS_ACCESS_KEY_ID=your_access_key"
        log_info "  export AWS_SECRET_ACCESS_KEY=your_secret_key"
        log_info "  Use IAM roles or AWS SSO"
        exit 1
    fi
    
    local caller_identity=$(aws sts get-caller-identity --query 'Account' --output text)
    log_success "AWS credentials configured for account: $caller_identity"
}

# Generate secure random password
generate_password() {
    local length=${1:-32}
    # Generate a secure random password with mixed case, numbers, and safe symbols
    openssl rand -base64 $((length * 3 / 4)) | tr -d "=+/" | cut -c1-$length
}

# Generate API key
generate_api_key() {
    local prefix=${1:-"sk"}
    echo "${prefix}-$(openssl rand -hex 16)"
}

# Create secret in AWS Secrets Manager
create_secret() {
    local secret_name="$1"
    local secret_value="$2"
    local description="$3"
    
    local full_secret_name="${SECRET_PREFIX}${secret_name}"
    
    log_info "Creating secret: $full_secret_name"
    
    # Check if secret already exists
    if aws secretsmanager describe-secret --secret-id "$full_secret_name" --region "$REGION" &> /dev/null; then
        log_warning "Secret $full_secret_name already exists"
        
        # Ask user if they want to update it
        read -p "Do you want to update the existing secret? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            aws secretsmanager update-secret \
                --secret-id "$full_secret_name" \
                --secret-string "$secret_value" \
                --region "$REGION" \
                --description "$description" \
                > /dev/null
            log_success "Updated secret: $full_secret_name"
        else
            log_info "Skipped updating secret: $full_secret_name"
        fi
    else
        # Create new secret
        aws secretsmanager create-secret \
            --name "$full_secret_name" \
            --secret-string "$secret_value" \
            --region "$REGION" \
            --description "$description" \
            --tags "[{\"Key\":\"Environment\",\"Value\":\"$ENVIRONMENT\"},{\"Key\":\"ManagedBy\",\"Value\":\"terraform\"},{\"Key\":\"Purpose\",\"Value\":\"ecs-http-server\"}]" \
            > /dev/null
        log_success "Created secret: $full_secret_name"
    fi
}

# Create JSON secret in AWS Secrets Manager
create_json_secret() {
    local secret_name="$1"
    local secret_json="$2"
    local description="$3"
    
    local full_secret_name="${SECRET_PREFIX}${secret_name}"
    
    log_info "Creating JSON secret: $full_secret_name"
    
    # Check if secret already exists
    if aws secretsmanager describe-secret --secret-id "$full_secret_name" --region "$REGION" &> /dev/null; then
        log_warning "Secret $full_secret_name already exists"
        
        # Ask user if they want to update it
        read -p "Do you want to update the existing secret? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            aws secretsmanager update-secret \
                --secret-id "$full_secret_name" \
                --secret-string "$secret_json" \
                --region "$REGION" \
                --description "$description" \
                > /dev/null
            log_success "Updated JSON secret: $full_secret_name"
        else
            log_info "Skipped updating secret: $full_secret_name"
        fi
    else
        # Create new secret
        aws secretsmanager create-secret \
            --name "$full_secret_name" \
            --secret-string "$secret_json" \
            --region "$REGION" \
            --description "$description" \
            --tags "[{\"Key\":\"Environment\",\"Value\":\"$ENVIRONMENT\"},{\"Key\":\"ManagedBy\",\"Value\":\"terraform\"},{\"Key\":\"Purpose\",\"Value\":\"ecs-http-server\"}]" \
            > /dev/null
        log_success "Created JSON secret: $full_secret_name"
    fi
}

# Create individual secrets
create_individual_secrets() {
    log_info "Creating individual secrets..."
    
    # Database credentials
    local db_password=$(generate_password 24)
    create_secret "database_password" "$db_password" "Database password for HTTP server"
    
    # API keys
    local api_key=$(generate_api_key "sk")
    create_secret "api_key" "$api_key" "External API key for third-party services"
    
    local third_party_key=$(generate_api_key "tpk")
    create_secret "third_party_api_key" "$third_party_key" "Third-party service API key"
    
    # JWT signing key (base64 encoded for security)
    local jwt_key=$(openssl rand -base64 64 | tr -d '\n')
    create_secret "jwt_signing_key" "$jwt_key" "JWT token signing key (base64 encoded)"
    
    # Redis password
    local redis_password=$(generate_password 20)
    create_secret "redis_password" "$redis_password" "Redis instance password"
    
    # Encryption key (32 bytes for AES-256, base64 encoded)
    local encryption_key=$(openssl rand -base64 32 | tr -d '\n')
    create_secret "encryption_key" "$encryption_key" "AES-256 encryption key (base64 encoded)"
    
    # OAuth credentials
    local oauth_secret=$(generate_password 40)
    create_secret "oauth_client_secret" "$oauth_secret" "OAuth client secret for authentication"
    
    # SMTP password
    local smtp_password=$(generate_password 16)
    create_secret "smtp_password" "$smtp_password" "SMTP server password for email delivery"
    
    log_success "Individual secrets created successfully"
}

# Create database configuration as JSON secret
create_database_config() {
    log_info "Creating database configuration secret..."
    
    local db_host="db.example.internal"
    local db_port="5432"
    local db_name="httpserver"
    local db_user="app_user"
    local db_password=$(generate_password 24)
    
    local db_config=$(cat <<EOF
{
    "host": "$db_host",
    "port": $db_port,
    "database": "$db_name",
    "username": "$db_user",
    "password": "$db_password",
    "ssl_mode": "require",
    "max_connections": 20,
    "connection_timeout": 30
}
EOF
)
    
    create_json_secret "database_config" "$db_config" "Database configuration (JSON) for HTTP server"
    
    log_success "Database configuration secret created"
}

# Create Redis configuration as JSON secret
create_redis_config() {
    log_info "Creating Redis configuration secret..."
    
    local redis_host="redis.example.internal"
    local redis_port="6379"
    local redis_password=$(generate_password 20)
    
    local redis_config=$(cat <<EOF
{
    "host": "$redis_host",
    "port": $redis_port,
    "password": "$redis_password",
    "db": 0,
    "ssl": true,
    "max_connections": 10,
    "timeout": 5
}
EOF
)
    
    create_json_secret "redis_config" "$redis_config" "Redis configuration (JSON) for HTTP server"
    
    log_success "Redis configuration secret created"
}

# Create OAuth configuration as JSON secret
create_oauth_config() {
    log_info "Creating OAuth configuration secret..."
    
    local client_id="http_server_$(openssl rand -hex 8)"
    local client_secret=$(generate_password 40)
    local auth_url="https://auth.example.com/oauth/authorize"
    local token_url="https://auth.example.com/oauth/token"
    
    local oauth_config=$(cat <<EOF
{
    "client_id": "$client_id",
    "client_secret": "$client_secret",
    "auth_url": "$auth_url",
    "token_url": "$token_url",
    "scope": "read write admin",
    "redirect_uri": "https://http-server.example.local/oauth/callback"
}
EOF
)
    
    create_json_secret "oauth_config" "$oauth_config" "OAuth configuration (JSON) for HTTP server"
    
    log_success "OAuth configuration secret created"
}

# Create external service credentials
create_external_service_secrets() {
    log_info "Creating external service secrets..."
    
    # AWS S3 credentials (for file storage)
    local s3_access_key="AKIA$(openssl rand -hex 8 | tr '[:lower:]' '[:upper:]')"
    local s3_secret_key=$(openssl rand -base64 30 | tr -d '\n')
    
    local s3_config=$(cat <<EOF
{
    "access_key_id": "$s3_access_key",
    "secret_access_key": "$s3_secret_key",
    "region": "$REGION",
    "bucket": "http-server-storage-bucket",
    "prefix": "uploads/"
}
EOF
)
    
    create_json_secret "s3_credentials" "$s3_config" "AWS S3 credentials for file storage"
    
    # Email service configuration
    local email_config=$(cat <<EOF
{
    "smtp_host": "smtp.example.com",
    "smtp_port": 587,
    "username": "http-server@example.com",
    "password": "$(generate_password 16)",
    "use_tls": true,
    "from_email": "noreply@example.com",
    "from_name": "HTTP Server Application"
}
EOF
)
    
    create_json_secret "email_config" "$email_config" "Email service configuration"
    
    # Monitoring/analytics service API key
    local monitoring_key=$(generate_api_key "mon")
    create_secret "monitoring_api_key" "$monitoring_key" "Monitoring service API key"
    
    log_success "External service secrets created"
}

# Create feature flags configuration
create_feature_flags() {
    log_info "Creating feature flags configuration..."
    
    local feature_flags=$(cat <<EOF
{
    "enable_new_ui": true,
    "enable_analytics": true,
    "enable_cache": true,
    "enable_debug_mode": false,
    "max_upload_size_mb": 10,
    "rate_limit_per_minute": 100,
    "maintenance_mode": false,
    "beta_features": {
        "advanced_search": true,
        "real_time_updates": false,
        "ai_suggestions": true
    }
}
EOF
)
    
    create_json_secret "feature_flags" "$feature_flags" "Feature flags configuration for HTTP server"
    
    log_success "Feature flags configuration created"
}

# List created secrets
list_created_secrets() {
    log_info "Listing created secrets..."
    
    echo -e "\n${BLUE}Created Secrets in AWS Secrets Manager:${NC}"
    
    # Get all secrets with the prefix
    local secrets=$(aws secretsmanager list-secrets \
        --region "$REGION" \
        --query "SecretList[?starts_with(Name, '${SECRET_PREFIX}')].{Name:Name,Description:Description}" \
        --output table)
    
    if [ -n "$secrets" ]; then
        echo "$secrets"
    else
        log_warning "No secrets found with prefix: $SECRET_PREFIX"
    fi
}

# Create IAM policy for ECS tasks to access secrets
create_iam_policy() {
    log_info "Creating IAM policy for secrets access..."
    
    local policy_name="ECS-HTTP-Server-Secrets-Policy"
    local policy_document=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret"
            ],
            "Resource": [
                "arn:aws:secretsmanager:${REGION}:*:secret:${SECRET_PREFIX}*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "kms:ViaService": "secretsmanager.${REGION}.amazonaws.com"
                }
            }
        }
    ]
}
EOF
)
    
    # Create policy file
    echo "$policy_document" > /tmp/secrets-policy.json
    
    # Check if policy already exists
    if aws iam get-policy --policy-arn "arn:aws:iam::$(aws sts get-caller-identity --query 'Account' --output text):policy/$policy_name" &> /dev/null; then
        log_warning "IAM policy $policy_name already exists"
        log_info "You may want to update it manually or delete and recreate"
    else
        # Create the policy
        local policy_arn=$(aws iam create-policy \
            --policy-name "$policy_name" \
            --policy-document file:///tmp/secrets-policy.json \
            --description "Policy for ECS HTTP server to access secrets" \
            --query 'Policy.Arn' \
            --output text)
        
        log_success "IAM policy created: $policy_arn"
        
        echo -e "\n${YELLOW}Important:${NC} Attach this policy to your ECS task role"
        echo "Policy ARN: $policy_arn"
    fi
    
    # Clean up temp file
    rm -f /tmp/secrets-policy.json
}

# Create sample secrets sidecar application
create_sidecar_example() {
    log_info "Creating sample secrets sidecar application..."
    
    mkdir -p ./sidecar
    
    # Create Python sidecar application
    cat > ./sidecar/app.py <<EOF
#!/usr/bin/env python3
"""
Secrets Sidecar Application
A simple HTTP server that fetches secrets from AWS Secrets Manager
and provides them to other containers in the same task.
"""

import json
import logging
import os
import time
from typing import Optional, Dict, Any

import boto3
from flask import Flask, jsonify, request
from botocore.exceptions import ClientError, NoCredentialsError

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration
REGION = os.getenv('AWS_DEFAULT_REGION', '${REGION}')
SECRET_PREFIX = os.getenv('SECRET_PREFIX', '${SECRET_PREFIX}')
PORT = int(os.getenv('PORT', '8080'))
CACHE_TTL = int(os.getenv('CACHE_TTL', '300'))  # 5 minutes

# Initialize Flask app
app = Flask(__name__)

# Initialize AWS Secrets Manager client
try:
    secrets_client = boto3.client('secretsmanager', region_name=REGION)
    logger.info(f"Initialized Secrets Manager client for region: {REGION}")
except NoCredentialsError:
    logger.error("AWS credentials not found")
    secrets_client = None

# In-memory cache for secrets
secrets_cache: Dict[str, Dict[str, Any]] = {}


def get_secret_from_aws(secret_name: str) -> Optional[str]:
    """Fetch secret from AWS Secrets Manager"""
    if not secrets_client:
        logger.error("Secrets Manager client not initialized")
        return None
    
    try:
        full_secret_name = f"{SECRET_PREFIX}{secret_name}"
        logger.info(f"Fetching secret: {full_secret_name}")
        
        response = secrets_client.get_secret_value(SecretId=full_secret_name)
        return response['SecretString']
    
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'ResourceNotFoundException':
            logger.error(f"Secret not found: {secret_name}")
        elif error_code == 'AccessDenied':
            logger.error(f"Access denied for secret: {secret_name}")
        else:
            logger.error(f"Error fetching secret {secret_name}: {e}")
        return None
    
    except Exception as e:
        logger.error(f"Unexpected error fetching secret {secret_name}: {e}")
        return None


def get_cached_secret(secret_name: str) -> Optional[str]:
    """Get secret from cache or fetch from AWS if not cached or expired"""
    now = time.time()
    
    # Check if secret is in cache and not expired
    if secret_name in secrets_cache:
        cached_data = secrets_cache[secret_name]
        if now - cached_data['timestamp'] < CACHE_TTL:
            logger.debug(f"Returning cached secret: {secret_name}")
            return cached_data['value']
        else:
            logger.debug(f"Cache expired for secret: {secret_name}")
    
    # Fetch from AWS
    secret_value = get_secret_from_aws(secret_name)
    
    if secret_value is not None:
        # Cache the secret
        secrets_cache[secret_name] = {
            'value': secret_value,
            'timestamp': now
        }
        logger.info(f"Cached secret: {secret_name}")
    
    return secret_value


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': time.time(),
        'cache_size': len(secrets_cache)
    })


@app.route('/secrets/<secret_name>', methods=['GET'])
def get_secret(secret_name: str):
    """Get a specific secret"""
    if not secret_name:
        return jsonify({'error': 'Secret name is required'}), 400
    
    secret_value = get_cached_secret(secret_name)
    
    if secret_value is None:
        return jsonify({'error': f'Secret not found: {secret_name}'}), 404
    
    # Try to parse as JSON, return as string if not JSON
    try:
        parsed_value = json.loads(secret_value)
        return jsonify({
            'secret_name': secret_name,
            'value': parsed_value,
            'type': 'json'
        })
    except json.JSONDecodeError:
        return jsonify({
            'secret_name': secret_name,
            'value': secret_value,
            'type': 'string'
        })


@app.route('/secrets', methods=['GET'])
def list_secrets():
    """List all cached secrets (names only, not values)"""
    return jsonify({
        'cached_secrets': list(secrets_cache.keys()),
        'cache_ttl': CACHE_TTL,
        'region': REGION,
        'secret_prefix': SECRET_PREFIX
    })


@app.route('/cache/clear', methods=['POST'])
def clear_cache():
    """Clear the secrets cache"""
    secrets_cache.clear()
    logger.info("Secrets cache cleared")
    return jsonify({'message': 'Cache cleared successfully'})


@app.route('/cache/refresh/<secret_name>', methods=['POST'])
def refresh_secret(secret_name: str):
    """Force refresh a specific secret"""
    if secret_name in secrets_cache:
        del secrets_cache[secret_name]
    
    secret_value = get_cached_secret(secret_name)
    
    if secret_value is None:
        return jsonify({'error': f'Secret not found: {secret_name}'}), 404
    
    return jsonify({
        'message': f'Secret refreshed: {secret_name}',
        'timestamp': time.time()
    })


@app.errorhandler(Exception)
def handle_exception(e):
    """Global exception handler"""
    logger.error(f"Unhandled exception: {e}", exc_info=True)
    return jsonify({'error': 'Internal server error'}), 500


if __name__ == '__main__':
    logger.info(f"Starting secrets sidecar on port {PORT}")
    logger.info(f"Region: {REGION}")
    logger.info(f"Secret prefix: {SECRET_PREFIX}")
    logger.info(f"Cache TTL: {CACHE_TTL} seconds")
    
    app.run(host='0.0.0.0', port=PORT, debug=False)
EOF

    # Create requirements.txt
    cat > ./sidecar/requirements.txt <<EOF
Flask==2.3.3
boto3==1.34.0
botocore==1.34.0
Werkzeug==2.3.7
EOF

    # Create Dockerfile for sidecar
    cat > ./sidecar/Dockerfile <<EOF
FROM python:3.11-alpine

# Install required packages
RUN apk add --no-cache curl

# Set working directory
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY app.py .

# Create non-root user
RUN adduser -D -s /bin/sh appuser
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Start application
CMD ["python", "app.py"]
EOF

    # Create docker-compose for local testing
    cat > ./sidecar/docker-compose.yml <<EOF
version: '3.8'

services:
  secrets-sidecar:
    build: .
    ports:
      - "8080:8080"
    environment:
      - AWS_DEFAULT_REGION=${REGION}
      - SECRET_PREFIX=${SECRET_PREFIX}
      - PORT=8080
      - CACHE_TTL=300
    # Mount AWS credentials for local testing
    volumes:
      - ~/.aws:/home/appuser/.aws:ro
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

    # Create README for sidecar
    cat > ./sidecar/README.md <<EOF
# Secrets Sidecar Application

A lightweight HTTP server that fetches secrets from AWS Secrets Manager and provides them to other containers.

## Features

- Fetches secrets from AWS Secrets Manager
- In-memory caching with configurable TTL
- JSON and string secret support
- Health check endpoint
- RESTful API for secret retrieval

## API Endpoints

- \`GET /health\` - Health check
- \`GET /secrets/<name>\` - Get specific secret
- \`GET /secrets\` - List cached secrets
- \`POST /cache/clear\` - Clear cache
- \`POST /cache/refresh/<name>\` - Refresh specific secret

## Environment Variables

- \`AWS_DEFAULT_REGION\` - AWS region (default: ${REGION})
- \`SECRET_PREFIX\` - Secrets prefix (default: ${SECRET_PREFIX})
- \`PORT\` - Server port (default: 8080)
- \`CACHE_TTL\` - Cache TTL in seconds (default: 300)

## Local Testing

\`\`\`bash
# Build and run
docker-compose up --build

# Test endpoints
curl http://localhost:8080/health
curl http://localhost:8080/secrets/database_password
\`\`\`

## Deployment

This sidecar is designed to run alongside your main application container in the same ECS task.
EOF

    chmod +x ./sidecar/app.py
    log_success "Sample secrets sidecar created in ./sidecar/"
}

# Print summary
print_summary() {
    echo -e "\n${GREEN}=================== SECRETS SETUP COMPLETE ===================${NC}"
    
    echo -e "\n${BLUE}Created Secrets:${NC}"
    echo "🔐 Individual secrets (8 total)"
    echo "📊 Database configuration (JSON)"
    echo "🗄️  Redis configuration (JSON)"
    echo "🔑 OAuth configuration (JSON)"
    echo "☁️  S3 credentials (JSON)"
    echo "📧 Email configuration (JSON)"
    echo "📊 Monitoring API key"
    echo "🎛️  Feature flags (JSON)"
    
    echo -e "\n${BLUE}Created IAM Resources:${NC}"
    echo "📜 IAM policy for ECS task secrets access"
    
    echo -e "\n${BLUE}Sample Applications:${NC}"
    echo "🐍 Python secrets sidecar (./sidecar/)"
    echo "🐳 Docker configuration"
    echo "📝 API documentation"
    
    echo -e "\n${BLUE}Next Steps:${NC}"
    echo "1. 📋 Review the created secrets in AWS Console"
    echo "2. 🔗 Attach the IAM policy to your ECS task role"
    echo "3. 🧪 Test the sidecar application locally"
    echo "4. 🐳 Build and push Docker images to ECR"
    echo "5. 🚀 Deploy using Terraform"
    
    echo -e "\n${BLUE}Secret Access:${NC}"
    echo "🌐 Region: $REGION"
    echo "📁 Prefix: $SECRET_PREFIX"
    echo "🏷️  Tags: Environment=$ENVIRONMENT, ManagedBy=terraform"
    
    echo -e "\n${YELLOW}Security Notes:${NC}"
    echo "⚠️  Generated passwords are cryptographically secure"
    echo "🔒 Secrets are encrypted at rest in AWS"
    echo "🎯 IAM policy follows least-privilege principle"
    echo "⏰ Sidecar implements caching to reduce API calls"
    echo "🔄 Consider implementing secret rotation"
    
    echo -e "\n${GREEN}Secrets setup completed successfully!${NC}"
}

# Main execution
main() {
    echo -e "${GREEN}=================== AWS SECRETS MANAGER SETUP ===================${NC}"
    echo -e "${BLUE}Setting up dummy secrets for ECS HTTP server${NC}"
    echo -e "${BLUE}Region: $REGION${NC}"
    echo -e "${BLUE}Secret prefix: $SECRET_PREFIX${NC}\n"
    
    check_aws_cli
    check_aws_credentials
    create_individual_secrets
    create_database_config
    create_redis_config
    create_oauth_config
    create_external_service_secrets
    create_feature_flags
    create_iam_policy
    create_sidecar_example
    list_created_secrets
    print_summary
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -p|--prefix)
            SECRET_PREFIX="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --dry-run)
            log_info "Dry run mode - no secrets will be created"
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Create dummy secrets in AWS Secrets Manager for ECS HTTP server"
            echo ""
            echo "Options:"
            echo "  -r, --region REGION      AWS region (default: us-west-2)"
            echo "  -p, --prefix PREFIX      Secret name prefix (default: http-server/)"
            echo "  -e, --environment ENV    Environment tag (default: development)"
            echo "      --dry-run           Show what would be created without creating"
            echo "  -h, --help              Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Use defaults"
            echo "  $0 -r us-east-1 -p myapp/            # Custom region and prefix"
            echo "  $0 -e production                     # Production environment"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Check if dry run mode
if [ "${DRY_RUN:-false}" = "true" ]; then
    log_warning "Dry run mode - no actual secrets will be created"
    log_info "Would create secrets with prefix: $SECRET_PREFIX"
    log_info "Would use region: $REGION"
    log_info "Would tag with environment: $ENVIRONMENT"
    exit 0
fi

# Run main function
main