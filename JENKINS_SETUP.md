# Jenkins Pipeline Setup Guide

## 🔧 Jenkins Credentials Configuration

Before running the Jenkins pipeline, you need to configure the following credentials in Jenkins:

### 1. Access Jenkins
Your Jenkins instance is running at: **http://20.246.206.92:8080**

### 2. Add Credentials in Jenkins
Go to **Manage Jenkins > Manage Credentials > Global > Add Credentials**

Add the following credentials with these exact IDs:

#### Azure Service Principal Credentials
- **azure-client-id**: `Secret text` - Your Azure Service Principal Client ID
- **azure-client-secret**: `Secret text` - Your Azure Service Principal Client Secret  
- **azure-tenant-id**: `Secret text` - Your Azure Tenant ID: `95d0cea2-a137-4263-8ed0-6df9842288b4`
- **azure-subscription-id**: `Secret text` - Your Azure Subscription ID: `e2930ce0-3e8a-4ab8-a728-4b82ac7a0d10`

#### Azure Container Registry Credentials
- **acr-username**: `Secret text` - ACR Username: `researchreportacr2287129`
- **acr-password**: `Secret text` - ACR Password: `[GET_FROM_AZURE_CLI]` (run: `az acr credential show --name researchreportacr2287129`)

#### Storage Account Credentials
- **storage-account-name**: `Secret text` - Storage Account Name: `reportapp287129`
- **storage-account-key**: `Secret text` - Storage Account Access Key: `[GET_FROM_AZURE_CLI]` (run: `az storage account keys list --resource-group research-report-app-rg --account-name reportapp287129`)

#### API Keys (Required for the Application)
- **openai-api-key**: `Secret text` - Your OpenAI API Key
- **google-api-key**: `Secret text` - Your Google API Key  
- **groq-api-key**: `Secret text` - Your Groq API Key
- **tavily-api-key**: `Secret text` - Your Tavily API Key
- **llm-provider**: `Secret text` - LLM provider name (e.g., "openai", "groq", etc.)

## 🚀 Deployment Steps

### Step 1: Build and Push Docker Image
First, build and push the Docker image to ACR:

```bash
./build-and-push-docker-image.sh
```

### Step 2: Configure Jenkins Pipeline
1. In Jenkins, create a new Pipeline job
2. Under "Pipeline Definition", select "Pipeline script from SCM"
3. Set SCM to "Git"
4. Repository URL: `https://github.com/your-username/automated-research-report-generation.git`
5. Branch: `*/main` (or your branch)
6. Script Path: `Jenkinsfile`

### Step 3: Run the Pipeline
1. Click "Build Now" to start the pipeline
2. Monitor the build progress in the Console Output
3. The pipeline will deploy your application to Azure Container Apps

## 🔍 Get Azure Resource Information

Use these commands to get the values needed for Jenkins credentials:

```bash
# Get Service Principal details (if you have them saved)
# These were created during infrastructure setup

# Get ACR credentials
az acr credential show --name researchreportacr2287129

# Get storage account details
az storage account list --resource-group research-report-app-rg --query "[].{Name:name}" --output table
az storage account keys list --resource-group research-report-app-rg --account-name [STORAGE_ACCOUNT_NAME]

# Get subscription and tenant IDs
az account show --query "{subscriptionId:id, tenantId:tenantId}"
```

## 📋 Pipeline Features

The Jenkins pipeline includes:

✅ **Code Checkout** - Pulls latest code from Git repository
✅ **Python Environment Setup** - Configures Python 3.11 environment  
✅ **Dependency Installation** - Installs requirements.txt packages
✅ **Basic Testing** - Validates application imports
✅ **Azure Authentication** - Logs into Azure using Service Principal
✅ **Docker Image Verification** - Checks for available images in ACR
✅ **Container App Deployment** - Deploys/updates Azure Container Apps
✅ **Health Check** - Verifies application is responding
✅ **Secret Management** - Securely configures API keys

## 🌐 Application Access

After successful deployment, your application will be available at:
`https://research-report-app.{region}.azurecontainerapps.io`

You can get the exact URL with:
```bash
az containerapp show --name research-report-app --resource-group research-report-app-rg --query properties.configuration.ingress.fqdn -o tsv
```

## 🚨 Troubleshooting
## Makesure No sensitive information mentioned here
## Fixed the Key value for  APi Keys

1. **Pipeline fails with authentication errors**: Verify Service Principal credentials in Jenkins
2. **Image not found in ACR**: Run `./build-and-push-docker-image.sh` first
3. **Container App deployment fails**: Check Azure resource limits and quotas
4. **Application not responding**: Check Container App logs in Azure Portal

For detailed logs:
```bash
az containerapp logs show --name research-report-app --resource-group research-report-app-rg --follow
```