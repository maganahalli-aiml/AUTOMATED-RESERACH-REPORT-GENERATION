#!/bin/bash

# Quick Azure Resource Status Check and Process Cleanup
echo "🔍 Azure Resource Status Check"
echo "=============================="

# Check if logged into Azure
if ! az account show > /dev/null 2>&1; then
    echo "❌ Not logged into Azure CLI"
    echo "💡 Run: az login"
    exit 1
fi

echo "📋 Current Azure subscription:"
az account show --query "{name:name, id:id}" --output table

echo ""
echo "🔍 Checking for research-related resource groups..."

# Check for resource groups
RESEARCH_GROUPS=$(az group list --query "[?contains(name, 'research') || contains(name, 'jenkins')].{Name:name, State:properties.provisioningState}" --output table 2>/dev/null)

if [ -z "$RESEARCH_GROUPS" ] || echo "$RESEARCH_GROUPS" | grep -q "No results"; then
    echo "✅ No research-related resource groups found"
    echo "💰 Azure costs: \$0.00 (no resources)"
else
    echo "📊 Found resource groups:"
    echo "$RESEARCH_GROUPS"
    
    echo ""
    echo "📋 Detailed resource inventory:"
    
    # List resources in each group
    for rg in $(az group list --query "[?contains(name, 'research') || contains(name, 'jenkins')].name" -o tsv 2>/dev/null); do
        echo ""
        echo "📁 Resource Group: $rg"
        az resource list --resource-group "$rg" --query "[].{Name:name, Type:type, Location:location}" --output table 2>/dev/null || echo "   ⚠️ Unable to list resources"
    done
fi

echo ""
echo "🔍 Checking for running Azure deletion processes..."

# Check for running deletion scripts
DELETION_PROCESSES=$(ps aux | grep -E "(delete-all-azure|azure.*delete)" | grep -v grep | grep -v "status-check")

if [ ! -z "$DELETION_PROCESSES" ]; then
    echo "⚠️  Found running deletion processes:"
    echo "$DELETION_PROCESSES"
    echo ""
    echo "🛑 To kill these processes, run:"
    echo "   ps aux | grep 'delete-all-azure' | grep -v grep | awk '{print \$2}' | xargs kill -9"
    echo ""
    read -p "Kill running deletion processes now? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🛑 Killing deletion processes..."
        ps aux | grep 'delete-all-azure' | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null || echo "No processes to kill"
        echo "✅ Deletion processes terminated"
    fi
else
    echo "✅ No running deletion processes found"
fi

echo ""
echo "📊 Current Azure Cost Status:"
if [ -z "$RESEARCH_GROUPS" ] || echo "$RESEARCH_GROUPS" | grep -q "No results"; then
    echo "   💰 Estimated monthly cost: \$0.00"
    echo "   ✅ All resources deleted successfully"
else
    echo "   💰 Estimated monthly cost: \$5-50 (depending on running services)"
    echo "   💡 Run ./stop-azure-services.sh to minimize costs"
    echo "   💡 Run ./delete-all-azure-resources.sh to eliminate all costs"
fi

echo ""
echo "🎯 Available Actions:"
echo "   🔄 Start services: ./start-azure-services.sh"
echo "   🛑 Stop services: ./stop-azure-services.sh"  
echo "   💀 Delete everything: ./delete-all-azure-resources.sh"
echo "   🔍 Check status: ./azure-status-check.sh"

echo ""
echo "✅ Status check complete!"