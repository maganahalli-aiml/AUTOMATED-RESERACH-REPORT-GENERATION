#!/bin/bash

# Azure Service Restart Script
# This script restarts/starts Azure resources that were stopped for cost savings

set -e

echo "🚀 Azure Service Restart Script"
echo "==============================="

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
echo "🔄 Starting service restart process..."

# 1. Start Container Instances (Jenkins)
echo ""
echo "1️⃣  Starting Jenkins Container Instances..."
CONTAINER_INSTANCES=$(az container list --resource-group $JENKINS_RG --query "[?instanceView.state=='Stopped'].name" -o tsv 2>/dev/null || echo "")
if [ ! -z "$CONTAINER_INSTANCES" ]; then
    for instance in $CONTAINER_INSTANCES; do
        echo "   🚀 Starting Container Instance: $instance"
        az container start --name $instance --resource-group $JENKINS_RG || echo "   ⚠️  Failed to start $instance"
    done
else
    echo "   ℹ️  No stopped Container Instances found (may already be running)"
fi

# 2. Start Virtual Machines
echo ""
echo "2️⃣  Starting Virtual Machines..."
VMS_JENKINS=$(az vm list --resource-group $JENKINS_RG --show-details --query "[?powerState=='VM deallocated'].name" -o tsv 2>/dev/null || echo "")
VMS_APP=$(az vm list --resource-group $APP_RG --show-details --query "[?powerState=='VM deallocated'].name" -o tsv 2>/dev/null || echo "")

for vm in $VMS_JENKINS; do
    if [ ! -z "$vm" ]; then
        echo "   🚀 Starting VM: $vm (Jenkins RG)"
        az vm start --name $vm --resource-group $JENKINS_RG --no-wait || echo "   ⚠️  Failed to start $vm"
    fi
done

for vm in $VMS_APP; do
    if [ ! -z "$vm" ]; then
        echo "   🚀 Starting VM: $vm (App RG)"
        az vm start --name $vm --resource-group $APP_RG --no-wait || echo "   ⚠️  Failed to start $vm"
    fi
done

if [ -z "$VMS_JENKINS" ] && [ -z "$VMS_APP" ]; then
    echo "   ℹ️  No deallocated Virtual Machines found"
fi

# 3. Scale up Container Apps
echo ""
echo "3️⃣  Scaling up Container Apps..."
CONTAINER_APPS=$(az containerapp list --resource-group $APP_RG --query "[].name" -o tsv 2>/dev/null || echo "")
if [ ! -z "$CONTAINER_APPS" ]; then
    for app in $CONTAINER_APPS; do
        echo "   📈 Scaling up Container App: $app"
        az containerapp update --name $app --resource-group $APP_RG --min-replicas 1 --max-replicas 3 || echo "   ⚠️  Failed to scale $app"
    done
else
    echo "   ℹ️  No Container Apps found"
fi

# 4. Wait for services to start and check status
echo ""
echo "4️⃣  Waiting for services to start..."
sleep 30

# 5. Get service endpoints
echo ""
echo "5️⃣  Service Endpoints:"

# Jenkins URL
JENKINS_IP=$(az container show --resource-group $JENKINS_RG --name jenkins-research-report --query ipAddress.ip --output tsv 2>/dev/null || echo "")
if [ ! -z "$JENKINS_IP" ]; then
    echo "   🔧 Jenkins: http://$JENKINS_IP:8080"
else
    echo "   ⚠️  Jenkins IP not found (may still be starting)"
fi

# Container App URL
CONTAINER_APP_URL=$(az containerapp show --name research-report-app --resource-group $APP_RG --query properties.configuration.ingress.fqdn -o tsv 2>/dev/null || echo "")
if [ ! -z "$CONTAINER_APP_URL" ]; then
    echo "   🌐 Research Report App: https://$CONTAINER_APP_URL"
else
    echo "   ⚠️  Container App URL not found (may still be starting)"
fi

# 6. Show current resource status
echo ""
echo "6️⃣  Current Resource Status:"
echo ""
echo "📊 Active Resources:"
echo ""
echo "Jenkins Resources ($JENKINS_RG):"
az container list --resource-group $JENKINS_RG --query "[].{Name:name, State:instanceView.state, IP:ipAddress.ip}" --output table 2>/dev/null || echo "   ℹ️  No container instances found"

echo ""
echo "App Resources ($APP_RG):"
az containerapp list --resource-group $APP_RG --query "[].{Name:name, Replicas:properties.template.scale.minReplicas, URL:properties.configuration.ingress.fqdn}" --output table 2>/dev/null || echo "   ℹ️  No container apps found"

echo ""
echo "💰 Cost Impact:"
echo "   📈 Container Apps: Running (incurring compute costs)"
echo "   📈 Container Instances: Running (incurring compute costs)"
echo "   📈 Virtual Machines: Running (incurring compute costs)"
echo "   💡 Remember to stop services when not in use to minimize costs"

echo ""
echo "✅ Service restart complete!"
echo "🎯 Your services should be accessible within 2-3 minutes"

echo ""
echo "🛑 To stop services later and save costs, run: ./stop-azure-services.sh"