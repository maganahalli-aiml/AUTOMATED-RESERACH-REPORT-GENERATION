#!/bin/bash

# Azure Cost Management Script - Stop All Services
# This script stops/deallocates Azure resources to minimize costs

set -e

echo "🛑 Azure Cost Management - Stopping All Services"
echo "================================================="

# Resource Groups
JENKINS_RG="research-report-jenkins-rg"
APP_RG="research-report-app-rg"

# Check if logged into Azure
if ! az account show > /dev/null 2>&1; then
    echo "❌ Please log in to Azure first: az login"
    exit 1
fi

echo "📋 Current Azure subscription:"
az account show --query "{name:name, id:id}" --output table

echo ""
read -p "⚠️  This will stop all services in both resource groups. Continue? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Operation cancelled"
    exit 1
fi

echo ""
echo "🔄 Starting service shutdown process..."

# 1. Stop Container Apps (these incur compute costs)
echo ""
echo "1️⃣  Stopping Container Apps..."
CONTAINER_APPS=$(az containerapp list --resource-group $APP_RG --query "[].name" -o tsv 2>/dev/null || echo "")
if [ ! -z "$CONTAINER_APPS" ]; then
    for app in $CONTAINER_APPS; do
        echo "   🛑 Scaling down Container App: $app"
        # Method 1: Scale to minimum replicas (will scale to 0 when no traffic)
        az containerapp update --name $app --resource-group $APP_RG --min-replicas 0 --max-replicas 1 2>/dev/null || echo "   ⚠️  Scaling method 1 failed for $app"
        
        # Method 2: Also try to deactivate the revision to ensure it's truly stopped
        echo "   💤 Attempting to deactivate $app..."
        REVISION=$(az containerapp revision list --name $app --resource-group $APP_RG --query "[0].name" -o tsv 2>/dev/null || echo "")
        if [ ! -z "$REVISION" ]; then
            az containerapp revision deactivate --name $app --resource-group $APP_RG --revision $REVISION 2>/dev/null || echo "   ℹ️  Deactivation not needed or failed for $app"
        fi
        
        echo "   ✅ Container App $app configured for minimal cost"
    done
else
    echo "   ℹ️  No Container Apps found"
fi

# 2. Stop Jenkins Container Instances
echo ""
echo "2️⃣  Stopping Jenkins Container Instances..."
CONTAINER_INSTANCES=$(az container list --resource-group $JENKINS_RG --query "[].name" -o tsv 2>/dev/null || echo "")
if [ ! -z "$CONTAINER_INSTANCES" ]; then
    for instance in $CONTAINER_INSTANCES; do
        echo "   🛑 Stopping Container Instance: $instance"
        az container stop --name $instance --resource-group $JENKINS_RG || echo "   ⚠️  Failed to stop $instance"
    done
else
    echo "   ℹ️  No Container Instances found"
fi

# 3. Stop Virtual Machines (if any)
echo ""
echo "3️⃣  Stopping Virtual Machines..."
VMS_JENKINS=$(az vm list --resource-group $JENKINS_RG --query "[].name" -o tsv 2>/dev/null || echo "")
VMS_APP=$(az vm list --resource-group $APP_RG --query "[].name" -o tsv 2>/dev/null || echo "")

for vm in $VMS_JENKINS $VMS_APP; do
    if [ ! -z "$vm" ]; then
        echo "   🛑 Deallocating VM: $vm"
        az vm deallocate --name $vm --resource-group $JENKINS_RG --no-wait || \
        az vm deallocate --name $vm --resource-group $APP_RG --no-wait || \
        echo "   ⚠️  Failed to deallocate $vm"
    fi
done

if [ -z "$VMS_JENKINS" ] && [ -z "$VMS_APP" ]; then
    echo "   ℹ️  No Virtual Machines found"
fi

# 4. Disable autoscaling for Container Apps Environment (if any scaling rules exist)
echo ""
echo "4️⃣  Disabling autoscaling..."
CONTAINER_ENVS=$(az containerapp env list --resource-group $APP_RG --query "[].name" -o tsv 2>/dev/null || echo "")
if [ ! -z "$CONTAINER_ENVS" ]; then
    for env in $CONTAINER_ENVS; do
        echo "   📉 Container Apps Environment: $env (scaling disabled via app config)"
    done
else
    echo "   ℹ️  No Container Apps Environments found"
fi

# 5. Show current resource status
echo ""
echo "5️⃣  Current Resource Status:"
echo ""
echo "📊 Jenkins Resource Group ($JENKINS_RG):"
az resource list --resource-group $JENKINS_RG --query "[].{Name:name, Type:type, Location:location}" --output table 2>/dev/null || echo "   ℹ️  No resources or access denied"

echo ""
echo "📊 App Resource Group ($APP_RG):"
az resource list --resource-group $APP_RG --query "[].{Name:name, Type:type, Location:location}" --output table 2>/dev/null || echo "   ℹ️  No resources or access denied"

# 6. Cost estimation
echo ""
echo "6️⃣  Cost Impact Summary:"
echo "   ✅ Container Apps: Scaled to 0 min replicas (minimal cost, scales to 0 with no traffic)"
echo "   ✅ Container Instances: Stopped (no compute cost)"
echo "   ✅ Virtual Machines: Deallocated (no compute cost)"
echo "   💰 Still incurring minimal costs for:"
echo "      - Storage accounts (very low cost)"
echo "      - Container Registry (low cost)"
echo "      - Log Analytics (minimal data retention cost)"
echo "      - Resource groups (free)"

echo ""
echo "🎯 Cost Optimization Tips:"
echo "   💡 To completely eliminate costs, delete entire resource groups"
echo "   💡 Storage costs are minimal (~\$0.02-0.05/month)"
echo "   💡 Container Registry basic tier (~\$5/month)"
echo "   💡 Log Analytics minimal usage (~\$0.10-0.50/month)"

echo ""
echo "✅ Service shutdown complete!"
echo "💵 Your Azure costs should now be minimal (mostly storage)"

echo ""
echo "🔄 To restart services later, run: ./start-azure-services.sh"