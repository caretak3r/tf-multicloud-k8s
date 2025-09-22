#!/bin/bash

# Create Secure EC2 Key Pair for ECS Deployment
# This script generates a highly secure RSA key pair for EC2 instances

set -euo pipefail  # Exit on any error, undefined variable, or pipe failure

# Configuration
KEYPAIR_NAME="secure-app-keypair"
AWS_REGION="us-west-2"
KEY_SIZE=4096  # 4096-bit RSA key for maximum security
PRIVATE_KEY_FILE="${KEYPAIR_NAME}.pem"
PUBLIC_KEY_FILE="${KEYPAIR_NAME}.pub"

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
    
    if ! command -v ssh-keygen &> /dev/null; then
        missing_tools+=("ssh-keygen")
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

# Function to generate secure private key
generate_private_key() {
    log_info "Generating $KEY_SIZE-bit RSA private key..."
    
    # Generate private key with strong encryption
    openssl genpkey \
        -algorithm RSA \
        -pkcs8 \
        -aes256 \
        -out "$PRIVATE_KEY_FILE" \
        -pkeyopt rsa_keygen_bits:$KEY_SIZE
    
    # Set secure permissions (read-only for owner)
    chmod 400 "$PRIVATE_KEY_FILE"
    
    log_success "Private key generated: $PRIVATE_KEY_FILE"
}

# Function to extract public key
generate_public_key() {
    log_info "Extracting public key from private key..."
    
    # Extract public key in OpenSSH format
    ssh-keygen -y -f "$PRIVATE_KEY_FILE" > "$PUBLIC_KEY_FILE"
    
    # Set secure permissions
    chmod 444 "$PUBLIC_KEY_FILE"
    
    log_success "Public key generated: $PUBLIC_KEY_FILE"
}

# Function to import key pair to AWS
import_to_aws() {
    log_info "Importing key pair to AWS EC2..."
    
    # Check if key pair already exists
    if aws ec2 describe-key-pairs --key-names "$KEYPAIR_NAME" --region "$AWS_REGION" &> /dev/null; then
        log_warning "Key pair '$KEYPAIR_NAME' already exists in AWS"
        echo -n "Do you want to delete and recreate it? (y/N): "
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            log_info "Deleting existing key pair..."
            aws ec2 delete-key-pair --key-name "$KEYPAIR_NAME" --region "$AWS_REGION"
            log_success "Existing key pair deleted"
        else
            log_info "Skipping AWS import. Using existing key pair."
            return 0
        fi
    fi
    
    # Import the public key to AWS
    aws ec2 import-key-pair \
        --key-name "$KEYPAIR_NAME" \
        --public-key-material "fileb://$PUBLIC_KEY_FILE" \
        --region "$AWS_REGION" > /dev/null
    
    log_success "Key pair imported to AWS: $KEYPAIR_NAME"
}

# Function to display key information
display_key_info() {
    echo
    log_info "=== Key Pair Information ==="
    log_info "Key pair name: $KEYPAIR_NAME"
    log_info "Key size: $KEY_SIZE bits"
    log_info "Private key file: $PRIVATE_KEY_FILE"
    log_info "Public key file: $PUBLIC_KEY_FILE"
    log_info "AWS Region: $AWS_REGION"
    echo
    
    # Display public key fingerprint
    local fingerprint
    fingerprint=$(ssh-keygen -lf "$PUBLIC_KEY_FILE" | awk '{print $2}')
    log_info "Public key fingerprint: $fingerprint"
    
    # Display file sizes
    local private_size public_size
    private_size=$(stat -f%z "$PRIVATE_KEY_FILE" 2>/dev/null || stat -c%s "$PRIVATE_KEY_FILE" 2>/dev/null || echo "unknown")
    public_size=$(stat -f%z "$PUBLIC_KEY_FILE" 2>/dev/null || stat -c%s "$PUBLIC_KEY_FILE" 2>/dev/null || echo "unknown")
    log_info "Private key size: $private_size bytes"
    log_info "Public key size: $public_size bytes"
}

# Function to create backup
create_backup() {
    local backup_dir="keypair-backup-$(date +%Y%m%d-%H%M%S)"
    
    echo -n "Do you want to create a backup of the key pair? (Y/n): "
    read -r response
    
    if [[ "$response" =~ ^[Nn]$ ]]; then
        return 0
    fi
    
    mkdir -p "$backup_dir"
    cp "$PRIVATE_KEY_FILE" "$backup_dir/"
    cp "$PUBLIC_KEY_FILE" "$backup_dir/"
    
    log_success "Backup created in: $backup_dir"
    log_warning "Store this backup in a secure location!"
}

# Function to validate key pair
validate_key_pair() {
    log_info "Validating key pair..."
    
    # Check if private key is valid
    if ! openssl pkey -in "$PRIVATE_KEY_FILE" -check -noout &> /dev/null; then
        log_error "Private key validation failed"
        return 1
    fi
    
    # Check if public key is valid
    if ! ssh-keygen -lf "$PUBLIC_KEY_FILE" &> /dev/null; then
        log_error "Public key validation failed"
        return 1
    fi
    
    # Verify that public key matches private key
    local private_pub_key public_key
    private_pub_key=$(ssh-keygen -y -f "$PRIVATE_KEY_FILE")
    public_key=$(cat "$PUBLIC_KEY_FILE")
    
    if [[ "$private_pub_key" != "$public_key" ]]; then
        log_error "Public and private keys do not match"
        return 1
    fi
    
    log_success "Key pair validation passed"
}

# Main script
main() {
    echo "============================================"
    echo "Secure EC2 Key Pair Generation Script"
    echo "============================================"
    echo
    log_info "This script will generate a $KEY_SIZE-bit RSA key pair for EC2 instances"
    log_info "Key pair name: $KEYPAIR_NAME"
    log_info "AWS Region: $AWS_REGION"
    echo
    
    # Check dependencies and AWS configuration
    check_dependencies
    check_aws_cli
    
    # Check if files already exist
    if [[ -f "$PRIVATE_KEY_FILE" ]] || [[ -f "$PUBLIC_KEY_FILE" ]]; then
        log_warning "Key files already exist in current directory"
        echo -n "Do you want to overwrite them? (y/N): "
        read -r response
        
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Operation cancelled by user"
            exit 0
        fi
        
        rm -f "$PRIVATE_KEY_FILE" "$PUBLIC_KEY_FILE"
    fi
    
    # Confirm before proceeding
    echo -n "Do you want to continue with key generation? (Y/n): "
    read -r response
    if [[ "$response" =~ ^[Nn]$ ]]; then
        log_info "Operation cancelled by user"
        exit 0
    fi
    
    echo
    log_info "=== Generating Key Pair ==="
    
    # Generate private key (will prompt for passphrase)
    generate_private_key
    
    # Generate public key
    generate_public_key
    
    # Validate key pair
    validate_key_pair
    
    # Import to AWS
    import_to_aws
    
    # Display information
    display_key_info
    
    # Create backup
    create_backup
    
    echo
    log_success "Key pair generation completed successfully!"
    echo
    log_info "=== Security Recommendations ==="
    log_warning "• Store the private key ($PRIVATE_KEY_FILE) in a secure location"
    log_warning "• Never share the private key or commit it to version control"
    log_warning "• The private key is encrypted with AES-256 - remember your passphrase!"
    log_warning "• Consider using SSH agent for key management"
    log_warning "• Regularly rotate your key pairs for better security"
    echo
    log_info "=== Next Steps ==="
    log_info "1. Update your terraform.tfvars with: bastion_key_name = \"$KEYPAIR_NAME\""
    log_info "2. Run ./generate-certs.sh to generate TLS certificates"
    log_info "3. Run ./upload-secrets.sh to upload application secrets"
    log_info "4. Deploy your infrastructure with terraform apply"
    echo
    log_info "=== SSH Connection Example ==="
    log_info "ssh -i $PRIVATE_KEY_FILE ec2-user@<instance-ip>"
    echo
}

# Handle script interruption
trap 'log_error "Script interrupted by user"; exit 1' INT TERM

# Run main function
main "$@"