#!/bin/bash

# Test ACR connectivity and image availability
# This script helps debug ACR issues in Jenkins

set -e

ACR_NAME="researchreportacr2287129"
IMAGE_NAME="research-report-app"

echo "🔍 Testing ACR connectivity..."

# Test Azure CLI login status
echo "📋 Checking Azure CLI login status..."
if az account show > /dev/null 2>&1; then
    SUBSCRIPTION=$(az account show --query name -o tsv)
    echo "✅ Logged into Azure subscription: $SUBSCRIPTION"
else
    echo "❌ Not logged into Azure CLI"
    exit 1
fi

# Test ACR login (skip if Docker not available)
echo "🔑 Testing ACR access..."
if command -v docker &> /dev/null && docker info &> /dev/null; then
    echo "Docker is available, attempting ACR login..."
    if az acr login --name $ACR_NAME; then
        echo "✅ Successfully logged into ACR: $ACR_NAME"
    else
        echo "❌ Failed to login to ACR: $ACR_NAME"
        exit 1
    fi
else
    echo "⚠️  Docker not available, skipping ACR login (using Azure CLI authentication)"
fi

# List all repositories
echo "📂 Listing all repositories in ACR..."
az acr repository list --name $ACR_NAME --output table

# Check if our specific repository exists
echo "🔍 Checking for repository: $IMAGE_NAME"
if az acr repository list --name $ACR_NAME --query "[?contains(@, '$IMAGE_NAME')]" --output tsv | grep -q "$IMAGE_NAME"; then
    echo "✅ Repository $IMAGE_NAME exists"
    
    # Show all tags
    echo "🏷️  Available tags for $IMAGE_NAME:"
    az acr repository show-tags --name $ACR_NAME --repository $IMAGE_NAME --output table
    
    # Get latest tag
    LATEST_TAG=$(az acr repository show-tags --name $ACR_NAME --repository $IMAGE_NAME --orderby time_desc --output tsv | head -n 1)
    echo "🎯 Latest tag: $LATEST_TAG"
    
    # Show image details
    echo "📊 Image details:"
    az acr repository show --name $ACR_NAME --repository $IMAGE_NAME --output table
    
else
    echo "❌ Repository $IMAGE_NAME not found"
    echo "Available repositories:"
    az acr repository list --name $ACR_NAME --output table
    exit 1
fi

echo "✅ ACR connectivity test completed successfully!"