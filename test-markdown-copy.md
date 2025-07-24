---
layout: default
title: "Test Markdown Copy Functionality"
---

# Test Markdown Copy Functionality

This page demonstrates that copy buttons work automatically with Markdown code blocks.

## SQL Query Example

```sql
-- Basic pass-through query
SELECT 
    deviceId,
    timestamp,
    temperature,
    humidity,
    System.Timestamp() AS ProcessedTime
INTO [blob-output]
FROM [telemetry-input]
```

## PowerShell Example

```powershell
# Connect to Azure and set variables
Connect-AzAccount
$resourceGroupName = "rg-streamanalytics-workshop"
$eventhubNamespaceName = "YOUR_EVENTHUB_NAMESPACE_NAME"
```

## Python Example

```python
import json
import asyncio
from azure.eventhub import EventHubProducerClient, EventData

async def send_telemetry_data():
    producer = EventHubProducerClient.from_connection_string(
        conn_str=connection_string,
        eventhub_name=eventhub_name
    )
    
    # Create sample telemetry data
    telemetry_data = {
        "deviceId": "device-001",
        "temperature": 25.5,
        "humidity": 60.2,
        "pressure": 1013.25
    }
```

## JSON Configuration Example

```json
{
  "deviceId": "device-001",
  "timestamp": "2024-01-15T14:30:25.123Z",
  "temperature": 25.5,
  "humidity": 60.2,
  "pressure": 1013.25,
  "location": {
    "lat": 47.6062,
    "lon": -122.3321
  }
}
```

## Bash/CLI Example

```bash
# Azure CLI commands
az login
az group create --name rg-streamanalytics-workshop --location eastus
az eventhubs namespace create --resource-group rg-streamanalytics-workshop --name my-eventhub-namespace
```

## Inline Code

This is inline code `SELECT * FROM table` which should NOT have a copy button.

All the code blocks above should have copy buttons when viewed through Jekyll!
