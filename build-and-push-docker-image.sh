#!/bin/bash

# Build and Push Docker Image to Azure Container Registry
# This script builds the Docker image and pushes it to ACR

set -e

# Configuration
ACR_NAME="researchreportacr2287129"
IMAGE_NAME="research-report-app"
TAG="latest"

echo "🔧 Building and pushing Docker image to Azure Container Registry..."

# Check if logged into Azure
if ! az account show > /dev/null 2>&1; then
    echo "❌ Please log in to Azure first: az login"
    exit 1
fi

# Login to ACR
echo "🔑 Logging into Azure Container Registry..."
az acr login --name $ACR_NAME

# Build Docker image
echo "🐳 Building Docker image..."
docker build -t ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${TAG} .

# Push to ACR
echo "📤 Pushing image to ACR..."
docker push ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${TAG}

# Tag with current timestamp for versioning
TIMESTAMP=$(date +%Y%m%d%H%M%S)
docker tag ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${TAG} ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${TIMESTAMP}
docker push ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${TIMESTAMP}

echo "✅ Successfully built and pushed image:"
echo "   ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${TAG}"
echo "   ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${TIMESTAMP}"

# List available images
echo "📋 Available images in ACR:"
az acr repository show-tags --name $ACR_NAME --repository $IMAGE_NAME --output table

echo "🚀 Ready to deploy! You can now run the Jenkins pipeline."