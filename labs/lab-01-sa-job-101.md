---
layout: default
title: "Lab 1: Stream Analytics Job 101"
nav_order: 1
parent: Labs
---

# Lab 1: Stream Analytics Job 101 - Event Hub → Stream Analytics → Blob Storage

## 🎯 Lab Objectives

In this lab, you will:
- Create your first Azure Stream Analytics job
- Configure an Event Hub as input source
- Configure Blob Storage as output destination
- Write a basic Stream Analytics query
- Test the data flow with sample data
- Monitor job performance

## 📋 Prerequisites

- Completed [Prerequisites Setup](../setup/prerequisites-setup.md)
- Access to Azure Portal
- Event Hub namespace with `telemetry-data` event hub
- Storage account with `output` container
- Stream Analytics job created but not configured

## 🏗️ Architecture Overview

```
[Event Hub] → [Stream Analytics Job] → [Blob Storage]
     ↑                    ↑                   ↑
  Input Source        Processing Logic    Output Sink
```

## 📝 Step-by-Step Instructions

### Step 1: Configure Event Hub Input

1. **Navigate to Stream Analytics Job**:
   - Open Azure Portal
   - Go to your resource group `rg-streamanalytics-workshop`
   - Click on your Stream Analytics job `asa-telemetry-processing`

2. **Add Input**:
   - In the left menu, click **"Inputs"**
   - Click **"+ Add stream input"** → **"Event Hub"**

3. **Configure Event Hub Input**:
   ```
   Input alias: telemetry-input
   Event Hub namespace: [Your Event Hub namespace]
   Event Hub name: telemetry-data
   Event Hub consumer group: $Default
   Authentication mode: Connection string
   Event Hub policy name: RootManageSharedAccessKey
   Partition key: (leave empty)
   Event serialization format: JSON
   Encoding: UTF-8
   Event compression type: None
   ```

4. **Test Connection**:
   - Click **"Test"** to verify connectivity
   - Click **"Save"** when successful

### Step 2: Configure Blob Storage Output

1. **Add Output**:
   - In the left menu, click **"Outputs"**
   - Click **"+ Add"** → **"Blob storage/ADLS Gen2"**

2. **Configure Blob Storage Output**:
   ```
   Output alias: blob-output
   Storage account: [Your storage account]
   Container: output
   Path pattern: telemetry/{date}/{time}
   Date format: YYYY/MM/DD
   Time format: HH
   Event serialization format: JSON
   Encoding: UTF-8
   Format: Line separated
   Minimum rows: 100
   Maximum time: 1 minute
   ```

3. **Test Connection**:
   - Click **"Test"** to verify connectivity
   - Click **"Save"** when successful

### Step 3: Write Stream Analytics Query

1. **Open Query Editor**:
   - In the left menu, click **"Query"**
   - You'll see the query editor with a sample query

2. **Write Your First Query**:
   Replace the default query with:
   ```sql
   -- Basic pass-through query
   -- Selects all fields from input and sends to output
   SELECT 
       *,
       System.Timestamp() AS ProcessedTime
   INTO [blob-output]
   FROM [telemetry-input]
   ```

3. **Understanding the Query**:
   - `SELECT *`: Selects all fields from the input
   - `System.Timestamp()`: Adds processing timestamp
   - `INTO [blob-output]`: Specifies the output destination
   - `FROM [telemetry-input]`: Specifies the input source

4. **Save Query**:
   - Click **"Save query"**

### Step 4: Start the Stream Analytics Job

1. **Configure Job Settings**:
   - Click **"Overview"** in the left menu
   - Click **"Start"** button
   - Choose output start time:
     - **Now**: Processes events from current time
     - **Custom**: Processes events from specified time
     - **When last stopped**: Resumes from last position
   - Select **"Now"** for this lab
   - Click **"Start"**

2. **Monitor Job Startup**:
   - Job will transition through states: Starting → Running
   - This process typically takes 1-3 minutes

### Step 5: Generate Sample Data

Since we need data to test our pipeline, let's send some sample telemetry data to Event Hub.

#### Option A: Use Azure Portal Test Data (Recommended for beginners)

1. **Navigate to Event Hub**:
   - Go to your Event Hub namespace
   - Click on `telemetry-data` event hub
   - Click **"Generate data"** (if available)

#### Option B: Use PowerShell Script

1. **Install Azure PowerShell Module** (if not already installed):
   ```powershell
   Install-Module -Name Az -AllowClobber -Scope CurrentUser
   ```

2. **Create Sample Data Script**:
   Save this as `generate-sample-data.ps1`:
   ```powershell
   # Connect to Azure
   Connect-AzAccount
   
   # Set variables (replace with your values)
   $resourceGroupName = "rg-streamanalytics-workshop"
   $eventhubNamespaceName = "YOUR_EVENTHUB_NAMESPACE_NAME"
   $eventhubName = "telemetry-data"
   
   # Get Event Hub connection string
   $keys = Get-AzEventHubKey -ResourceGroupName $resourceGroupName -NamespaceName $eventhubNamespaceName -Name "RootManageSharedAccessKey"
   $connectionString = $keys.PrimaryConnectionString
   
   # Install Event Hubs library
   Install-Package Microsoft.Azure.EventHubs -Force
   
   # Sample data generator
   $sampleData = @"
   {
       "deviceId": "device-001",
       "timestamp": "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ')",
       "temperature": $(Get-Random -Minimum 20 -Maximum 40),
       "humidity": $(Get-Random -Minimum 30 -Maximum 80),
       "pressure": $(Get-Random -Minimum 1000 -Maximum 1100),
       "location": {
           "lat": 47.6062,
           "lon": -122.3321
       }
   }
   "@
   
   Write-Output "Sample telemetry data:"
   Write-Output $sampleData
   ```

3. **Run the Script**:
   ```powershell
   .\generate-sample-data.ps1
   ```

#### Option C: Use Azure CLI

1. **Send Sample Event**:
   ```bash
   # Set variables
   RESOURCE_GROUP="rg-streamanalytics-workshop"
   EVENTHUB_NAMESPACE="YOUR_EVENTHUB_NAMESPACE_NAME"
   EVENTHUB_NAME="telemetry-data"
   
   # Send sample data
   az eventhubs eventhub send \
     --resource-group $RESOURCE_GROUP \
     --namespace-name $EVENTHUB_NAMESPACE \
     --name $EVENTHUB_NAME \
     --body '{
       "deviceId": "device-001",
       "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'",
       "temperature": 25.5,
       "humidity": 60.2,
       "pressure": 1013.25,
       "location": {
         "lat": 47.6062,
         "lon": -122.3321
       }
     }'
   ```

### Step 6: Monitor Data Flow

1. **Check Stream Analytics Metrics**:
   - In your Stream Analytics job, click **"Monitoring"**
   - Look for:
     - **Input Events**: Should show incoming events
     - **Output Events**: Should show processed events
     - **Data Conversion Errors**: Should be 0

2. **Check Output in Blob Storage**:
   - Navigate to your storage account
   - Click **"Containers"** → **"output"**
   - You should see folders organized by date/time
   - Download and examine a JSON file to verify data

3. **Expected Output Format**:
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
     },
     "ProcessedTime": "2024-01-15T14:30:30.456Z"
   }
   ```

### Step 7: Explore Stream Analytics Features

1. **View Input Preview**:
   - Go to **"Inputs"** → Click on `telemetry-input`
   - Click **"Input preview"** to see recent events

2. **Test Query with Sample Data**:
   - Go to **"Query"**
   - Click **"Test query"**
   - Upload sample data or use live input
   - Verify query results

3. **Monitor Resource Utilization**:
   - Check **"Scale"** to see Streaming Units usage
   - Review **"Activity log"** for any issues

## 🔍 Verification Steps

1. **Verify Job is Running**:
   ```powershell
   az stream-analytics job show \
     --resource-group rg-streamanalytics-workshop \
     --name asa-telemetry-processing \
     --query "jobState"
   ```

2. **Check Input/Output Events**:
   - Navigate to job **"Overview"**
   - Verify Input events > 0
   - Verify Output events > 0
   - Ensure minimal or no errors

3. **Validate Output Data**:
   - Check blob storage for output files
   - Verify JSON structure and content
   - Confirm ProcessedTime field is added

## 🧪 Testing Scenarios

### Test 1: Multiple Device Data
Send data from multiple devices:
```json
{
  "deviceId": "device-002",
  "timestamp": "2024-01-15T14:35:00.000Z",
  "temperature": 22.1,
  "humidity": 55.7,
  "pressure": 1015.3,
  "location": {
    "lat": 40.7128,
    "lon": -74.0060
  }
}
```

### Test 2: Data with Missing Fields
Test resilience with incomplete data:
```json
{
  "deviceId": "device-003",
  "timestamp": "2024-01-15T14:40:00.000Z",
  "temperature": 28.3
}
```

### Test 3: High-Volume Data
Generate multiple events quickly to test throughput.

## 🐛 Troubleshooting

### Common Issues and Solutions

**Issue**: Job fails to start
- **Solution**: Check input/output connections, verify credentials

**Issue**: No input events showing
- **Solution**: Verify Event Hub has data, check consumer group

**Issue**: No output files in blob storage
- **Solution**: Check output configuration, verify storage permissions

**Issue**: Data conversion errors
- **Solution**: Verify JSON format, check for invalid characters

**Issue**: High SU% utilization
- **Solution**: Optimize query, consider scaling up

### Diagnostic Queries

1. **Check for Errors**:
   ```sql
   SELECT 
       System.Timestamp() AS EventTime,
       COUNT(*) AS ErrorCount
   FROM [telemetry-input]
   WHERE GetMetadataPropertyValue([telemetry-input], 'Error') IS NOT NULL
   GROUP BY TumblingWindow(minute, 1)
   ```

2. **Monitor Event Rate**:
   ```sql
   SELECT 
       System.Timestamp() AS WindowEnd,
       COUNT(*) AS EventCount
   FROM [telemetry-input]
   GROUP BY TumblingWindow(minute, 1)
   ```

## 📚 Key Concepts Learned

1. **Stream Analytics Job Components**:
   - Inputs (Event Hub, IoT Hub, Blob Storage)
   - Query (SQL-like processing logic)
   - Outputs (Storage, SQL DB, Power BI, etc.)

2. **Data Flow**:
   - Streaming data ingestion
   - Real-time processing
   - Continuous output generation

3. **Monitoring**:
   - Job metrics and health
   - Resource utilization
   - Error tracking

## 🎯 Lab Success Criteria

✅ Stream Analytics job successfully created and running  
✅ Event Hub input configured and receiving data  
✅ Blob Storage output configured and writing files  
✅ Basic pass-through query working correctly  
✅ Sample data flowing through the pipeline  
✅ Output files contain expected JSON structure  
✅ No conversion errors or job failures  

## 🚀 Next Steps

Congratulations! You've successfully created your first Stream Analytics pipeline. 

**Next Lab**: [Lab 2: Stream Analytics Query Language Overview](./lab-02-saql-overview.md)

In the next lab, you'll learn about:
- SAQL syntax and structure
- Data types and operators
- Built-in functions
- Query optimization techniques

## 📖 Additional Resources

- [Azure Stream Analytics Documentation](https://docs.microsoft.com/azure/stream-analytics/)
- [Stream Analytics Query Language Reference](https://docs.microsoft.com/stream-analytics-query/)
- [Event Hubs Documentation](https://docs.microsoft.com/azure/event-hubs/)
- [Azure Storage Documentation](https://docs.microsoft.com/azure/storage/)

---

**Estimated Completion Time**: 45-60 minutes  
**Difficulty Level**: Beginner  
**Cost Impact**: ~$1-2 for the duration of the lab
