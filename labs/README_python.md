# Azure Event Hub Python Sample Data Generator

This directory contains Python scripts that mimic the PowerShell functionality for sending sample telemetry data to Azure Event Hub on a periodic basis.

## Files

- **`generate_sample_data.py`** - Main script using Azure SDK (recommended)
- **`generate_sample_data_rest.py`** - Alternative script using REST API calls
- **`requirements.txt`** - Python package dependencies
- **`setup.py`** - Setup and configuration helper script
- **`README_python.md`** - This documentation file

## Features

✅ **Automatic dependency installation**  
✅ **Multiple authentication methods** (Azure CLI, environment variables)  
✅ **Comprehensive error handling and logging**  
✅ **Test connectivity before starting**  
✅ **Graceful shutdown with Ctrl+C**  
✅ **Detailed debugging information**  
✅ **Both Azure SDK and REST API approaches**  

## Quick Start

### 1. Setup and Installation

```bash
# Run the setup script to install dependencies
python setup.py

# Or manually install requirements
pip install -r requirements.txt
```

### 2. Configuration

#### Option A: Using Azure CLI (Recommended for Azure SDK version)
```bash
# Login to Azure
az login

# Make sure you're using the correct subscription
az account show
```

#### Option B: Using Connection String (For REST API version)
```bash
# Set environment variable (Windows)
set EVENTHUB_CONNECTION_STRING="Endpoint=sb://your-namespace.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=your-key"

# Set environment variable (Linux/Mac)
export EVENTHUB_CONNECTION_STRING="Endpoint=sb://your-namespace.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=your-key"
```

### 3. Update Configuration

Edit the configuration variables in the Python scripts:

```python
# In generate_sample_data.py or generate_sample_data_rest.py
RESOURCE_GROUP = "rg-streamanalytics-workshop"      # Your resource group
NAMESPACE_NAME = "eventhub-sa-workshop-1234"        # Your Event Hub namespace
EVENTHUB_NAME = "telemetry-data"                    # Your Event Hub name
SEND_INTERVAL = 5                                   # Seconds between messages
```

### 4. Run the Scripts

```bash
# Using Azure SDK (recommended)
python generate_sample_data.py

# Using REST API (alternative)
python generate_sample_data_rest.py
```

## Sample Data Format

The scripts generate telemetry data in the following format:

```json
{
  "deviceId": "device-042",
  "timestamp": "2025-07-22T10:30:45.123Z",
  "temperature": 28.5,
  "humidity": 65.2,
  "pressure": 1015.8,
  "location": {
    "lat": 47.6062,
    "lon": -122.3321
  }
}
```

## Script Comparison

| Feature | Azure SDK Version | REST API Version |
|---------|-------------------|------------------|
| **Dependencies** | Requires Azure libraries | Only requires `requests` |
| **Authentication** | Azure CLI, Managed Identity, Service Principal | Connection string only |
| **Configuration** | Auto-retrieves connection string | Manual connection string |
| **Reliability** | Higher (uses official SDK) | Good (direct REST calls) |
| **Error Handling** | Comprehensive | Good |
| **Best For** | Production, CI/CD pipelines | Simple scenarios, testing |

## Troubleshooting

### Common Issues

1. **"Azure libraries not found"**
   ```bash
   pip install azure-eventhub azure-identity azure-mgmt-eventhub
   ```

2. **"Failed to get connection string from Azure"**
   - Ensure you're logged into Azure CLI: `az login`
   - Check you have permissions to the Event Hub namespace
   - Verify resource group and namespace names are correct

3. **"Connection string missing Endpoint"**
   - Check your connection string format
   - Ensure all required parts are present: Endpoint, SharedAccessKeyName, SharedAccessKey

4. **"No such host is known"**
   - Check your network connectivity
   - Verify the namespace name is correct
   - Ensure the Event Hub namespace exists

### Getting Connection String

You can get your Event Hub connection string from:

1. **Azure Portal:**
   - Go to your Event Hub namespace
   - Select "Shared access policies"
   - Click on "RootManageSharedAccessKey"
   - Copy the "Connection string-primary key"

2. **Azure CLI:**
   ```bash
   az eventhubs namespace authorization-rule keys list \
     --resource-group rg-streamanalytics-workshop \
     --namespace-name eventhub-sa-workshop-1234 \
     --name RootManageSharedAccessKey \
     --query primaryConnectionString -o tsv
   ```

## Monitoring

The scripts provide detailed logging:

- **INFO**: General operation status
- **ERROR**: Failed operations
- **DEBUG**: Detailed debugging information

To enable debug logging, modify the logging level:

```python
logging.basicConfig(level=logging.DEBUG)
```

## Security Notes

- Keep your connection strings secure
- Use environment variables instead of hardcoding secrets
- Consider using Azure Managed Identity in production
- Rotate access keys regularly

## Dependencies

- **azure-eventhub**: Official Azure Event Hubs SDK
- **azure-identity**: Azure authentication library
- **azure-mgmt-eventhub**: Azure Event Hub management client
- **requests**: HTTP library for REST API calls

## License

This sample is provided as-is for educational purposes.
