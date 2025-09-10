# Secrets Manager Sidecar

A lightweight Python Flask application that provides a REST API for accessing AWS Secrets Manager secrets from within ECS containers.

## Features

- Secure access to AWS Secrets Manager secrets
- JSON and string secret support
- Health check endpoint
- Key-specific secret retrieval
- Comprehensive error handling
- Non-root container execution

## API Endpoints

- `GET /health` - Health check endpoint
- `GET /secret/<secret_name>` - Get entire secret value
- `GET /secret/<secret_name>/<key>` - Get specific key from JSON secret
- `GET /secrets` - List available secrets with configured prefix

## Environment Variables

- `AWS_REGION` - AWS region (default: us-east-1)
- `SECRETS_PREFIX` - Prefix for filtering secrets (default: empty)

## Usage from Main Container

```bash
# Get a secret
curl http://localhost:5000/secret/database-credentials

# Get a specific key from a JSON secret
curl http://localhost:5000/secret/database-credentials/password

# Health check
curl http://localhost:5000/health
```

## Building the Image

```bash
docker build -t secrets-sidecar:latest .
```