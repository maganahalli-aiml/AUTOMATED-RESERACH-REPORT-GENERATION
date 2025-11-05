#!/bin/bash

# Verify and fix Container Apps Environment
set -e

RESOURCE_GROUP="research-report-app-rg"
ENV_NAME="research-report-env"
LOCATION="eastus"

echo "🔍 Checking Container Apps Environment..."

# Check if environment exists and get its state
if az containerapp env show --name $ENV_NAME --resource-group $RESOURCE_GROUP > /dev/null 2>&1; then
    ENV_STATE=$(az containerapp env show --name $ENV_NAME --resource-group $RESOURCE_GROUP --query properties.provisioningState -o tsv)
    echo "✅ Environment '$ENV_NAME' exists with state: $ENV_STATE"
    
    if [ "$ENV_STATE" != "Succeeded" ]; then
        echo "⚠️  Environment is not in Succeeded state. Current state: $ENV_STATE"
        echo "🔄 Recreating environment..."
        
        # Delete the problematic environment
        echo "🗑️  Deleting existing environment..."
        az containerapp env delete --name $ENV_NAME --resource-group $RESOURCE_GROUP --yes
        
        # Wait a bit for deletion to complete
        echo "⏳ Waiting for deletion to complete..."
        sleep 30
        
        # Create new environment
        echo "🆕 Creating new Container Apps environment..."
        az containerapp env create \
          --name $ENV_NAME \
          --resource-group $RESOURCE_GROUP \
          --location $LOCATION
        
        # Wait for creation to complete
        echo "⏳ Waiting for environment to be ready..."
        for i in $(seq 1 20); do
            if az containerapp env show --name $ENV_NAME --resource-group $RESOURCE_GROUP > /dev/null 2>&1; then
                ENV_STATE=$(az containerapp env show --name $ENV_NAME --resource-group $RESOURCE_GROUP --query properties.provisioningState -o tsv)
                echo "Attempt $i: state=$ENV_STATE"
                if [ "$ENV_STATE" = "Succeeded" ]; then
                    echo "✅ Environment is ready!"
                    break
                fi
            fi
            sleep 15
        done
    else
        echo "✅ Environment is ready and in Succeeded state"
    fi
else
    echo "❌ Environment '$ENV_NAME' does not exist"
    echo "🆕 Creating Container Apps environment..."
    
    az containerapp env create \
      --name $ENV_NAME \
      --resource-group $RESOURCE_GROUP \
      --location $LOCATION
    
    # Wait for creation to complete
    echo "⏳ Waiting for environment to be ready..."
    for i in $(seq 1 20); do
        if az containerapp env show --name $ENV_NAME --resource-group $RESOURCE_GROUP > /dev/null 2>&1; then
            ENV_STATE=$(az containerapp env show --name $ENV_NAME --resource-group $RESOURCE_GROUP --query properties.provisioningState -o tsv)
            echo "Attempt $i: state=$ENV_STATE"
            if [ "$ENV_STATE" = "Succeeded" ]; then
                echo "✅ Environment is ready!"
                break
            fi
        fi
        sleep 15
    done
fi

# Final verification
echo "🔍 Final verification..."
az containerapp env show --name $ENV_NAME --resource-group $RESOURCE_GROUP --query "{name:name, state:properties.provisioningState, location:location}" --output table

echo "✅ Container Apps environment is ready for deployment!"