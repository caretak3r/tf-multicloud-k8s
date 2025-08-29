#!/bin/bash

# Build script for secrets-sidecar container
# Usage: ./build.sh [IMAGE_NAME] [TAG]

IMAGE_NAME=${1:-secrets-sidecar}
TAG=${2:-latest}
FULL_IMAGE_NAME="${IMAGE_NAME}:${TAG}"

echo "Building secrets-sidecar Docker image: $FULL_IMAGE_NAME"

# Build the Docker image
docker build -t "$FULL_IMAGE_NAME" .

if [ $? -eq 0 ]; then
    echo "✅ Successfully built $FULL_IMAGE_NAME"
    echo ""
    echo "To push to ECR:"
    echo "1. Create ECR repository: aws ecr create-repository --repository-name $IMAGE_NAME"
    echo "2. Get login token: aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account>.dkr.ecr.<region>.amazonaws.com"
    echo "3. Tag image: docker tag $FULL_IMAGE_NAME <account>.dkr.ecr.<region>.amazonaws.com/$IMAGE_NAME:$TAG"
    echo "4. Push image: docker push <account>.dkr.ecr.<region>.amazonaws.com/$IMAGE_NAME:$TAG"
    echo ""
    echo "To test locally:"
    echo "docker run -p 8080:8080 -e AWS_REGION=us-east-1 -e SECRETS_PREFIX=myapp/ $FULL_IMAGE_NAME"
else
    echo "❌ Failed to build $FULL_IMAGE_NAME"
    exit 1
fi