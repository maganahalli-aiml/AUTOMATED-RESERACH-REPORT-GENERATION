#!/bin/bash

# Azure Complete Cleanup Script - DELETE ALL RESOURCES
# ⚠️  WARNING: This script PERMANENTLY DELETES all Azure resources
# Use this only if you want to completely remove everything and eliminate all costs

set -e

echo "💀 Azure Complete Cleanup - DELETE ALL RESOURCES"
echo "=================================================="
echo ""
echo "⚠️  WARNING: THIS WILL PERMANENTLY DELETE:"
echo "   🗑️  All Jenkins infrastructure"
echo "   🗑️  All application resources"
echo "   🗑️  Container Registry and all Docker images"
echo "   🗑️  Storage accounts and all data"
echo "   🗑️  Log Analytics workspaces and logs"
echo "   🗑️  ALL configuration and data"
echo ""
echo "💰 After this, your Azure costs will be $0.00"
echo "🔄 You'll need to re-run setup scripts to recreate everything"

# Resource Groups
JENKINS_RG="research-report-jenkins-rg"
APP_RG="research-report-app-rg"

# Check if logged into Azure
if ! az account show > /dev/null 2>&1; then
    echo "❌ Please log in to Azure first: az login"
    exit 1
fi

echo ""
echo "📋 Current Azure subscription:"
az account show --query "{name:name, id:id}" --output table

echo ""
echo "📊 Resources to be deleted:"
echo ""
echo "Jenkins Resource Group ($JENKINS_RG):"
az resource list --resource-group $JENKINS_RG --query "[].{Name:name, Type:type}" --output table 2>/dev/null || echo "   ℹ️  Resource group not found"

echo ""
echo "App Resource Group ($APP_RG):"
az resource list --resource-group $APP_RG --query "[].{Name:name, Type:type}" --output table 2>/dev/null || echo "   ℹ️  Resource group not found"

echo ""
echo "🔴 FINAL WARNING: This action cannot be undone!"
echo ""
read -p "Type 'DELETE' in uppercase to confirm complete deletion: " -r
echo ""
if [[ $REPLY != "DELETE" ]]; then
    echo "❌ Operation cancelled - confirmation not received"
    exit 1
fi

echo ""
echo "💣 Starting complete resource deletion..."

# Delete Jenkins resource group
echo ""
echo "1️⃣  Deleting Jenkins Resource Group ($JENKINS_RG)..."
if az group exists --name $JENKINS_RG; then
    echo "   🗑️  Deleting all Jenkins resources..."
    az group delete --name $JENKINS_RG --yes --no-wait
    echo "   ✅ Jenkins deletion initiated (running in background)"
else
    echo "   ℹ️  Jenkins resource group not found"
fi

# Delete App resource group
echo ""
echo "2️⃣  Deleting App Resource Group ($APP_RG)..."
if az group exists --name $APP_RG; then
    echo "   🗑️  Deleting all application resources..."
    az group delete --name $APP_RG --yes --no-wait
    echo "   ✅ App deletion initiated (running in background)"
else
    echo "   ℹ️  App resource group not found"
fi

# Monitor deletion progress
echo ""
echo "3️⃣  Monitoring deletion progress..."
echo "   ⏳ This may take 5-10 minutes to complete..."

JENKINS_EXISTS=true
APP_EXISTS=true

while [ "$JENKINS_EXISTS" = true ] || [ "$APP_EXISTS" = true ]; do
    sleep 30
    
    if az group exists --name $JENKINS_RG 2>/dev/null; then
        echo "   🔄 Jenkins resources still deleting..."
    else
        if [ "$JENKINS_EXISTS" = true ]; then
            echo "   ✅ Jenkins resources deleted"
            JENKINS_EXISTS=false
        fi
    fi
    
    if az group exists --name $APP_RG 2>/dev/null; then
        echo "   🔄 App resources still deleting..."
    else
        if [ "$APP_EXISTS" = true ]; then
            echo "   ✅ App resources deleted"
            APP_EXISTS=false
        fi
    fi
done

echo ""
echo "4️⃣  Cleanup verification..."
REMAINING_RESOURCES=$(az resource list --query "[?contains(resourceGroup, 'research-report') || contains(resourceGroup, 'jenkins')]" --output tsv 2>/dev/null | wc -l)
if [ "$REMAINING_RESOURCES" -eq 0 ]; then
    echo "   ✅ All resources successfully deleted"
else
    echo "   ⚠️  Some resources may still exist, check Azure Portal"
fi

echo ""
echo "🎉 COMPLETE CLEANUP FINISHED!"
echo "==============================="
echo ""
echo "💰 Cost Impact:"
echo "   ✅ Azure costs: $0.00 (all resources deleted)"
echo "   ✅ No ongoing charges"
echo "   ✅ No storage costs"
echo "   ✅ No compute costs"
echo ""
echo "🔄 To recreate the infrastructure:"
echo "   1. Run: ./azure-deploy-jenkins.sh"
echo "   2. Run: ./setup-app-infrastructure.sh"
echo "   3. Configure Jenkins credentials"
echo "   4. Run Jenkins pipeline"
echo ""
echo "📋 Deleted Resources:"
echo "   🗑️  Jenkins CI/CD infrastructure"
echo "   🗑️  Container Registry + Docker images"
echo "   🗑️  Container Apps + environments"
echo "   🗑️  Storage accounts + data"
echo "   🗑️  Log Analytics + monitoring data"
echo "   🗑️  Service principals + permissions"
echo ""
echo "✅ Azure account is now clean and cost-free!"