# Azure Cost Management Guide

## 💰 Cost Optimization Scripts

This repository includes scripts to help you manage Azure costs effectively:

### 🛑 Stop Services (Minimize Costs)
```bash
./stop-azure-services.sh
```
**What it does:**
- Scales Container Apps to 0 replicas
- Stops Jenkins Container Instances
- Deallocates Virtual Machines
- **Cost Impact**: ~95% cost reduction (only storage remains)
- **Monthly Cost**: ~$5-10 (mostly Container Registry)

### 🚀 Start Services (Resume Operations)
```bash
./start-azure-services.sh
```
**What it does:**
- Restarts Jenkins Container Instances
- Starts Virtual Machines
- Scales Container Apps back to 1-3 replicas
- **Cost Impact**: Full operational costs resume
- **Monthly Cost**: ~$20-50 (depending on usage)

### 💀 Delete Everything (Zero Costs)
```bash
./delete-all-azure-resources.sh
```
**⚠️  WARNING: Permanent deletion!**
- Deletes ALL Azure resources
- **Cost Impact**: $0.00 (everything removed)
- **Recovery**: Requires full infrastructure recreation

## 📊 Cost Breakdown

### Running Costs (Full Operation)
- **Container Apps**: ~$10-20/month (depending on traffic)
- **Jenkins Container Instance**: ~$5-15/month
- **Container Registry**: ~$5/month (Basic tier)
- **Storage**: ~$1-2/month
- **Log Analytics**: ~$1-3/month
- **Total**: ~$22-45/month

### Stopped Costs (Services Paused)
- **Container Apps**: ~$0/month (0 replicas)
- **Jenkins**: ~$0/month (stopped)
- **Container Registry**: ~$5/month (storage only)
- **Storage**: ~$1-2/month
- **Log Analytics**: ~$0.50/month (minimal data)
- **Total**: ~$6.50-7.50/month

### Deleted Costs (Everything Removed)
- **All Services**: $0.00/month
- **Total**: $0.00/month

## 🎯 Recommended Strategy

### For Development/Testing:
1. **During work**: Keep services running
2. **After work**: Run `./stop-azure-services.sh`
3. **Next day**: Run `./start-azure-services.sh`
4. **Weekend/vacation**: Keep stopped or delete if long-term

### For Production:
1. Keep services running continuously
2. Monitor costs in Azure Cost Management
3. Set up cost alerts and budgets

## ⚡ Quick Commands

```bash
# Daily shutdown (after work)
./stop-azure-services.sh

# Daily startup (before work) 
./start-azure-services.sh

# Check current costs
az consumption usage list --top 5

# Check running resources
az resource list --output table

# Monitor specific resource group
az resource list --resource-group research-report-app-rg --output table
```

## 🔄 Service Recovery

If you delete everything, recreate with:
```bash
# 1. Recreate infrastructure
./azure-deploy-jenkins.sh
./setup-app-infrastructure.sh

# 2. Configure Jenkins (see JENKINS_SETUP.md)
# 3. Run Jenkins pipeline to deploy application
```

## 📱 Cost Monitoring

Set up cost alerts in Azure Portal:
1. Go to Cost Management + Billing
2. Create Budget with alerts at $10, $25, $50
3. Set up daily cost notifications
4. Monitor usage patterns

## 💡 Pro Tips

- **Container Registry**: Major cost component when running
- **Container Apps**: Scale to 0 = no compute cost
- **Storage**: Very cheap, can keep indefinitely
- **Log Analytics**: Set retention to 30 days to minimize cost
- **Jenkins**: Can run on-demand basis for CI/CD