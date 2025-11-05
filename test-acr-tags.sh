#!/bin/bash

# Test script to verify ACR tag retrieval logic
set -e

ACR_NAME="researchreportacr2287129"
IMAGE_NAME="research-report-app"

echo "Testing ACR tag retrieval..."

# Get ACR credentials
ACR_CREDS=$(az acr credential show --name $ACR_NAME)
ACR_USERNAME=$(echo $ACR_CREDS | python3 -c "import json,sys; data=json.load(sys.stdin); print(data['username'])")
ACR_PASSWORD=$(echo $ACR_CREDS | python3 -c "import json,sys; data=json.load(sys.stdin); print(data['passwords'][0]['value'])")

echo "Testing REST API approach..."
LATEST_TAG=$(curl -s -u "${ACR_USERNAME}:${ACR_PASSWORD}" \
    "https://${ACR_NAME}.azurecr.io/v2/${IMAGE_NAME}/tags/list" | \
    python3 -c "import json,sys; data=json.load(sys.stdin); tags=data.get('tags', []); print(sorted(tags)[-1] if tags else '')")

echo "Latest tag from REST API: '$LATEST_TAG'"

echo "Testing Azure CLI approach..."
CLI_TAG=$(az acr repository show-tags \
  --name $ACR_NAME \
  --repository $IMAGE_NAME \
  --orderby time_desc \
  --output tsv | head -n 1)

echo "Latest tag from CLI: '$CLI_TAG'"

# Choose the best tag
if [ ! -z "$LATEST_TAG" ]; then
    FINAL_TAG="$LATEST_TAG"
    echo "Using REST API tag: $FINAL_TAG"
elif [ ! -z "$CLI_TAG" ]; then
    FINAL_TAG="$CLI_TAG"
    echo "Using CLI tag: $FINAL_TAG"
else
    echo "No tags found!"
    exit 1
fi

echo "Final tag to use: '$FINAL_TAG'"