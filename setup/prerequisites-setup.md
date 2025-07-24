# Prerequisites Setup Guide

This guide will help you set up all the Azure resources required for the Stream Analytics Workshop.

## 📋 Required Azure Resources

| Resource | Purpose | Estimated Cost (USD/month) |
|----------|---------|---------------------------|
| Event Hub Namespace | Data ingestion | $10-50 |
| IoT Hub | IoT device connectivity | $25-100 |
| Stream Analytics Job | Real-time processing | $80-200 |
| Azure SQL Database | Data storage | $15-100 |
| Storage Account | Blob storage, checkpoints | $5-20 |
| Power BI | Data visualization | $10-20/user |

## 🛠️ Setup Options

Choose one of the following setup methods:

### Option 1: Azure Portal (Manual Setup)
Follow the step-by-step instructions below to create resources manually.

### Option 2: Infrastructure as Code (Recommended)
Use the provided Bicep templates for automated deployment.

### Option 3: Azure CLI Scripts
Use PowerShell scripts for quick setup.

---

## 🔧 Option 1: Manual Setup via Azure Portal

### 1. Create Resource Group

1. Sign in to the [Azure Portal](https://portal.azure.com)
2. Click **"Create a resource"** → **"Resource group"**
3. Configure:
   - **Subscription**: Select your Azure subscription
   - **Resource group name**: `rg-streamanalytics-workshop`
   - **Region**: `East US` (or your preferred region)
4. Click **"Review + create"** → **"Create"**

### 2. Create Storage Account

1. Navigate to **"Create a resource"** → **"Storage account"**
2. Configure:
   - **Resource group**: `rg-streamanalytics-workshop`
   - **Storage account name**: `sastorageXXXXX` (replace XXXXX with random characters)
   - **Region**: Same as resource group
   - **Performance**: Standard
   - **Redundancy**: LRS (Locally-redundant storage)
3. Click **"Review + create"** → **"Create"**
4. After creation, create a container named `output`

### 3. Create Event Hub Namespace

1. Navigate to **"Create a resource"** → Search for **"Event Hubs"**
2. Configure:
   - **Resource group**: `rg-streamanalytics-workshop`
   - **Namespace name**: `eventhub-sa-workshop-XXXXX`
   - **Region**: Same as resource group
   - **Pricing tier**: Standard
3. Click **"Review + create"** → **"Create"**
4. After creation:
   - Navigate to the Event Hub namespace
   - Click **"+ Event Hub"**
   - Create an Event Hub named `telemetry-data`
   - Partition count: `2`
   - Message retention: `1` day

### 4. Create IoT Hub

1. Navigate to **"Create a resource"** → Search for **"IoT Hub"**
2. Configure:
   - **Resource group**: `rg-streamanalytics-workshop`
   - **IoT hub name**: `iothub-sa-workshop-XXXXX`
   - **Region**: Same as resource group
   - **Tier**: S1 (Standard)
3. Click **"Review + create"** → **"Create"**

### 5. Create Azure SQL Database

1. Navigate to **"Create a resource"** → **"SQL Database"**
2. Configure:
   - **Resource group**: `rg-streamanalytics-workshop`
   - **Database name**: `StreamAnalyticsDB`
   - **Server**: Create new server
     - **Server name**: `sqlserver-sa-workshop-XXXXX`
     - **Authentication**: SQL authentication
     - **Server admin login**: `sqladmin`
     - **Password**: Create a strong password
   - **Compute + storage**: Basic (5 DTU)
3. Configure networking:
   - **Allow Azure services**: Yes
   - **Add current client IP**: Yes
4. Click **"Review + create"** → **"Create"**

### 6. Create Stream Analytics Job

1. Navigate to **"Create a resource"** → Search for **"Stream Analytics job"**
2. Configure:
   - **Resource group**: `rg-streamanalytics-workshop`
   - **Job name**: `asa-telemetry-processing`
   - **Region**: Same as resource group
   - **Hosting environment**: Cloud
   - **Streaming units**: 1
3. Click **"Review + create"** → **"Create"**

---

## 🚀 Option 2: Infrastructure as Code (Bicep)

### Prerequisites
- Azure CLI installed
- Bicep CLI installed
- PowerShell (for Windows) or Bash (for Linux/macOS)

### Deployment Steps

1. **Clone or download the workshop repository**
2. **Navigate to the setup directory**:
   ```powershell
   cd d:\Samples\StreamAnalyticsWorkshop\setup\bicep
   ```

3. **Login to Azure**:
   ```powershell
   az login
   az account set --subscription "your-subscription-id"
   ```

4. **Deploy the infrastructure**:
   ```powershell
   az deployment group create `
     --resource-group rg-streamanalytics-workshop `
     --template-file main.bicep `
     --parameters @main.parameters.json
   ```

5. **Verify deployment**:
   ```powershell
   az resource list --resource-group rg-streamanalytics-workshop --output table
   ```

---

## 📜 Option 3: Azure CLI Scripts

### Prerequisites
- Azure CLI installed
- PowerShell (for Windows) or Bash (for Linux/macOS)

### Quick Setup Script

Run the following PowerShell script:

```powershell
# Set variables
$resourceGroup = "rg-streamanalytics-workshop"
$location = "East US"
$suffix = Get-Random -Maximum 99999

# Create resource group
az group create --name $resourceGroup --location $location

# Create storage account
$storageAccount = "sastorageaccount$suffix"
az storage account create `
  --name $storageAccount `
  --resource-group $resourceGroup `
  --location $location `
  --sku Standard_LRS

# Create storage container
az storage container create `
  --name output `
  --account-name $storageAccount

# Create Event Hub namespace and hub
$eventhubNamespace = "eventhub-sa-workshop-$suffix"
az eventhubs namespace create `
  --resource-group $resourceGroup `
  --name $eventhubNamespace `
  --location $location `
  --sku Standard

az eventhubs eventhub create `
  --resource-group $resourceGroup `
  --namespace-name $eventhubNamespace `
  --name telemetry-data `
  --partition-count 2

# Create IoT Hub
$iotHub = "iothub-sa-workshop-$suffix"
az iot hub create `
  --resource-group $resourceGroup `
  --name $iotHub `
  --location $location `
  --sku S1

# Create SQL Server and Database
$sqlServer = "sqlserver-sa-workshop-$suffix"
$sqlDatabase = "StreamAnalyticsDB"
$sqlAdmin = "sqladmin"
$sqlPassword = "P@ssw0rd123!" # Change this to a secure password

az sql server create `
  --resource-group $resourceGroup `
  --name $sqlServer `
  --location $location `
  --admin-user $sqlAdmin `
  --admin-password $sqlPassword

az sql db create `
  --resource-group $resourceGroup `
  --server $sqlServer `
  --name $sqlDatabase `
  --service-objective Basic

# Configure SQL Server firewall
az sql server firewall-rule create `
  --resource-group $resourceGroup `
  --server $sqlServer `
  --name AllowAzureServices `
  --start-ip-address 0.0.0.0 `
  --end-ip-address 0.0.0.0

# Create Stream Analytics Job
$streamAnalyticsJob = "asa-telemetry-processing"
az stream-analytics job create `
  --resource-group $resourceGroup `
  --name $streamAnalyticsJob `
  --location $location `
  --output-error-policy "Drop" `
  --events-outoforder-policy "Adjust" `
  --events-outoforder-max-delay 5 `
  --events-late-arrival-max-delay 5 `
  --data-locale "en-US"

Write-Output "Deployment completed successfully!"
Write-Output "Resource Group: $resourceGroup"
Write-Output "Storage Account: $storageAccount"
Write-Output "Event Hub Namespace: $eventhubNamespace"
Write-Output "IoT Hub: $iotHub"
Write-Output "SQL Server: $sqlServer"
Write-Output "Stream Analytics Job: $streamAnalyticsJob"
```

---

## 🔍 Verification Steps

After completing any setup option, verify your resources:

1. **Check Resource Group**:
   ```powershell
   az resource list --resource-group rg-streamanalytics-workshop --output table
   ```

2. **Test Event Hub**:
   - Navigate to Event Hub in Azure Portal
   - Verify the `telemetry-data` event hub exists
   - Check connection strings are available

3. **Test Storage Account**:
   - Verify the `output` container exists
   - Test connectivity

4. **Test SQL Database**:
   - Connect using SQL Server Management Studio or Azure Data Studio
   - Verify connection with the admin credentials

5. **Test IoT Hub**:
   - Navigate to IoT Hub in Azure Portal
   - Verify the hub is running

## 📝 Connection Strings and Keys

After setup, collect the following connection information (you'll need these for the labs):

### Event Hub
```powershell
az eventhubs namespace authorization-rule keys list `
  --resource-group rg-streamanalytics-workshop `
  --namespace-name YOUR_EVENTHUB_NAMESPACE `
  --name RootManageSharedAccessKey
```

### IoT Hub
```powershell
az iot hub connection-string show `
  --resource-group rg-streamanalytics-workshop `
  --hub-name YOUR_IOT_HUB_NAME
```

### Storage Account
```powershell
az storage account keys list `
  --resource-group rg-streamanalytics-workshop `
  --account-name YOUR_STORAGE_ACCOUNT_NAME
```

## 🧹 Cleanup

To remove all resources after the workshop:

```powershell
az group delete --name rg-streamanalytics-workshop --yes --no-wait
```

## ⚠️ Important Notes

1. **Cost Management**: Some resources incur charges immediately. Monitor your Azure spending.
2. **Security**: Change default passwords and use strong authentication.
3. **Regions**: Ensure all resources are in the same region for optimal performance.
4. **Naming**: Use consistent naming conventions with unique suffixes.
5. **Firewall**: Configure firewall rules for SQL Database to allow your IP address.

## 🆘 Troubleshooting

### Common Issues

**Resource naming conflicts**: Add random suffixes to resource names
**Permission errors**: Ensure you have Contributor access to the subscription
**Network connectivity**: Configure firewall rules for SQL Database
**Region availability**: Some regions may not support all services

### Getting Help

- Check Azure Resource Health in the portal
- Review Activity Logs for deployment errors
- Use Azure CLI with `--debug` flag for detailed error information
- Consult [Azure documentation](https://docs.microsoft.com/azure/)

---

**Next Step**: Once your prerequisites are set up, return to the main [README](../README.md) and start with [Lab 1: Stream Analytics Job 101](../labs/lab-01-sa-job-101.md)!
