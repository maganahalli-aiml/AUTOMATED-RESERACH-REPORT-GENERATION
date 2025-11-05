#!/bin/bash

# Test the exact Jenkins logic
set -e

ACR_NAME="researchreportacr2287129"
IMAGE_NAME="research-report-app"

echo "Testing simplified Jenkins ACR logic..."

# Replicate the exact Jenkins script
TAG=$(az acr repository show-tags \
  --name $ACR_NAME \
  --repository $IMAGE_NAME \
  --orderby time_desc \
  --output tsv 2>/dev/null | head -n 1)

if [ ! -z "$TAG" ]; then
    echo "Found tag: '$TAG'"
    echo "Image would be: ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${TAG}"
else
    echo "No tag found"
    exit 1
fi