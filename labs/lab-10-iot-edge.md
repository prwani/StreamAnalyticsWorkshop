---
layout: default
title: "Lab 10: IoT Edge Overview - Edge Analytics and Stream Processing"
nav_order: 10
parent: Labs
---

# Lab 10: IoT Edge Overview - Edge Analytics and Stream Processing

## 🎯 Lab Objectives

In this lab, you will:
- Understand Azure IoT Edge architecture and capabilities
- Deploy Stream Analytics on IoT Edge devices
- Implement edge-based data filtering and aggregation
- Configure local storage and offline scenarios
- Set up cloud-to-edge and edge-to-cloud data flows
- Monitor and manage edge deployments
- Compare edge vs cloud processing trade-offs
- Implement security best practices for edge scenarios

## 📋 Prerequisites

- Completed [Lab 9: Fabric RTI Overview](./lab-09-fabric-rti.md)
- Azure IoT Hub resource (can reuse from previous labs)
- Basic understanding of Docker containers
- Virtual machine or physical device for edge simulation
- Understanding of IoT device connectivity

## 🏗️ IoT Edge Architecture Overview

```
[IoT Devices] → [IoT Edge Device] → [IoT Hub] → [Stream Analytics/Fabric RTI]
                      ↓
               [Local Processing]
                      ↓
               [Edge Storage/Actions]
```

### Key Components:
- **IoT Edge Runtime**: Container management and communication
- **Edge Agent**: Module deployment and monitoring
- **Edge Hub**: Message routing and offline storage
- **Custom Modules**: Your business logic (including Stream Analytics)
- **IoT Edge Security Daemon**: Certificate management and security

## 📝 Step-by-Step Instructions

### Step 1: Set Up IoT Edge Environment

1. **Create IoT Edge Device Identity**:
   - Navigate to your IoT Hub in Azure Portal
   - Go to **"IoT Edge"** in the left menu
   - Click **"+ Add an IoT Edge device"**
   - Device ID: `edge-device-01`
   - Authentication: Symmetric key (auto-generate)
   - Save and copy the primary connection string

2. **Install IoT Edge Runtime** (Linux/Windows):
   
   **For Ubuntu/Linux**:
   ```bash
   # Download and install IoT Edge
   curl https://packages.microsoft.com/config/ubuntu/20.04/multiarch/packages-microsoft-prod.deb > ./packages-microsoft-prod.deb
   sudo dpkg -i ./packages-microsoft-prod.deb
   rm ./packages-microsoft-prod.deb
   
   sudo apt-get update
   sudo apt-get install aziot-edge
   
   # Configure the device connection string
   sudo iotedge config mp --connection-string "[YOUR_CONNECTION_STRING]"
   sudo iotedge config apply
   ```

   **For Windows**:
   ```powershell
   # Download and install IoT Edge for Windows
   . {Invoke-WebRequest -useb https://aka.ms/iotedge-win} | Invoke-Expression; Deploy-IoTEdge
   Initialize-IoTEdge -ManualConnectionString -ConnectionString "[YOUR_CONNECTION_STRING]"
   ```

3. **Verify Installation**:
   ```bash
   sudo iotedge check
   sudo iotedge list
   ```

### Step 2: Create Stream Analytics Edge Job

1. **Create New Stream Analytics Job**:
   - Go to Azure Portal → Stream Analytics jobs
   - Click **"+ Create"**
   - Name: `asa-edge-processing`
   - Hosting environment: **"Edge"**
   - Create the job

2. **Configure Edge Job Input**:
   ```json
   {
     "alias": "edge-input",
     "type": "Edge Hub",
     "serialization": {
       "type": "JSON",
       "encoding": "UTF8"
     }
   }
   ```

3. **Configure Edge Job Output**:
   ```json
   {
     "alias": "edge-output",
     "type": "Edge Hub",
     "serialization": {
       "type": "JSON",
       "encoding": "UTF8"
     }
   }
   ```

### Step 3: Edge Processing Queries

#### Query 1: Local Data Filtering
```sql
-- Filter critical temperature readings locally
SELECT 
    deviceId,
    timestamp,
    temperature,
    humidity,
    pressure,
    'CRITICAL' AS alertLevel,
    'High temperature detected at edge' AS message
INTO [edge-output]
FROM [edge-input]
WHERE temperature > 35 OR temperature < 5
```

#### Query 2: Local Aggregation to Reduce Cloud Traffic
```sql
-- Aggregate data every 5 minutes to reduce cloud bandwidth
SELECT 
    System.Timestamp() AS windowEnd,
    COUNT(*) AS eventCount,
    AVG(temperature) AS avgTemperature,
    MIN(temperature) AS minTemperature,
    MAX(temperature) AS maxTemperature,
    AVG(humidity) AS avgHumidity,
    AVG(pressure) AS avgPressure,
    -- Send alert flag if any reading was critical
    MAX(CASE WHEN temperature > 35 OR temperature < 5 THEN 1 ELSE 0 END) AS hasCriticalReading,
    -- Count of different alert types
    SUM(CASE WHEN temperature > 35 THEN 1 ELSE 0 END) AS highTempCount,
    SUM(CASE WHEN temperature < 5 THEN 1 ELSE 0 END) AS lowTempCount
INTO [edge-output]
FROM [edge-input]
GROUP BY TumblingWindow(minute, 5)
```

#### Query 3: Edge-based Anomaly Detection
```sql
-- Simplified anomaly detection at the edge
WITH RecentReadings AS (
    SELECT 
        deviceId,
        timestamp,
        temperature,
        AVG(temperature) OVER (
            PARTITION BY deviceId 
            ORDER BY timestamp 
            ROWS BETWEEN 10 PRECEDING AND CURRENT ROW
        ) AS rollingAvg,
        STDEV(temperature) OVER (
            PARTITION BY deviceId 
            ORDER BY timestamp 
            ROWS BETWEEN 10 PRECEDING AND CURRENT ROW
        ) AS rollingStdDev
    FROM [edge-input]
),
AnomalyDetection AS (
    SELECT 
        deviceId,
        timestamp,
        temperature,
        rollingAvg,
        rollingStdDev,
        ABS(temperature - rollingAvg) AS deviation,
        CASE 
            WHEN ABS(temperature - rollingAvg) > (2 * rollingStdDev) THEN 1 
            ELSE 0 
        END AS isAnomaly
    FROM RecentReadings
    WHERE rollingStdDev > 0  -- Avoid division by zero
)
SELECT 
    deviceId,
    timestamp,
    temperature,
    rollingAvg,
    deviation,
    isAnomaly,
    CASE 
        WHEN isAnomaly = 1 THEN 'ANOMALY_DETECTED'
        ELSE 'NORMAL'
    END AS status,
    'Edge detected anomaly: temp=' + CAST(temperature AS VARCHAR) + 
    ', avg=' + CAST(rollingAvg AS VARCHAR) AS alertMessage
INTO [edge-output]
FROM AnomalyDetection
WHERE isAnomaly = 1  -- Only send anomalies to cloud
```

#### Query 4: Multi-stage Processing with Local Storage
```sql
-- Store all data locally, send summaries to cloud
SELECT 
    deviceId,
    timestamp,
    temperature,
    humidity,
    pressure,
    'local-storage' AS target
INTO [local-storage]
FROM [edge-input]

-- Send hourly summaries to cloud
SELECT 
    System.Timestamp() AS summaryTime,
    'HOURLY_SUMMARY' AS messageType,
    COUNT(*) AS totalReadings,
    COUNT(DISTINCT deviceId) AS activeDevices,
    AVG(temperature) AS avgTemperature,
    MIN(temperature) AS minTemperature,
    MAX(temperature) AS maxTemperature,
    STDEV(temperature) AS tempStdDev,
    -- Quality metrics
    SUM(CASE WHEN temperature IS NULL THEN 1 ELSE 0 END) AS nullReadings,
    SUM(CASE WHEN temperature > 35 OR temperature < 5 THEN 1 ELSE 0 END) AS alertReadings
INTO [cloud-output]
FROM [edge-input]
GROUP BY TumblingWindow(hour, 1)
```

### Step 4: Deploy Stream Analytics to Edge

1. **Publish Edge Job**:
   - In your Stream Analytics Edge job, click **"Publish"**
   - This creates a Docker container with your query
   - Note the container image URI

2. **Create Deployment Manifest**:
   ```json
   {
     "modulesContent": {
       "$edgeAgent": {
         "properties.desired": {
           "schemaVersion": "1.1",
           "runtime": {
             "type": "docker",
             "settings": {
               "minDockerVersion": "v1.25",
               "loggingOptions": "",
               "registryCredentials": {}
             }
           },
           "systemModules": {
             "edgeAgent": {
               "type": "docker",
               "settings": {
                 "image": "mcr.microsoft.com/azureiotedge-agent:1.4",
                 "createOptions": {}
               }
             },
             "edgeHub": {
               "type": "docker",
               "status": "running",
               "restartPolicy": "always",
               "settings": {
                 "image": "mcr.microsoft.com/azureiotedge-hub:1.4",
                 "createOptions": {
                   "HostConfig": {
                     "PortBindings": {
                       "5671/tcp": [{"HostPort": "5671"}],
                       "8883/tcp": [{"HostPort": "8883"}],
                       "443/tcp": [{"HostPort": "443"}]
                     }
                   }
                 }
               },
               "env": {
                 "OptimizeForPerformance": {"value": "false"}
               }
             }
           },
           "modules": {
             "StreamAnalyticsModule": {
               "version": "1.0",
               "type": "docker",
               "status": "running",
               "restartPolicy": "always",
               "settings": {
                 "image": "[YOUR_STREAM_ANALYTICS_CONTAINER_IMAGE]",
                 "createOptions": {}
               }
             },
             "SimulatedTemperatureSensor": {
               "version": "1.0",
               "type": "docker",
               "status": "running",
               "restartPolicy": "always",
               "settings": {
                 "image": "mcr.microsoft.com/azureiotedge-simulated-temperature-sensor:1.4",
                 "createOptions": {}
               }
             }
           }
         }
       },
       "$edgeHub": {
         "properties.desired": {
           "schemaVersion": "1.2",
           "routes": {
             "SensorToASA": "FROM /messages/modules/SimulatedTemperatureSensor/outputs/temperatureOutput INTO BrokeredEndpoint(\"/modules/StreamAnalyticsModule/inputs/edge-input\")",
             "ASAToCloud": "FROM /messages/modules/StreamAnalyticsModule/outputs/edge-output INTO $upstream",
             "ASAToLocal": "FROM /messages/modules/StreamAnalyticsModule/outputs/local-storage INTO BrokeredEndpoint(\"/modules/LocalStorageModule/inputs/input1\")"
           },
           "storeAndForwardConfiguration": {
             "timeToLiveSecs": 7200
           }
         }
       }
     }
   }
   ```

3. **Deploy to Edge Device**:
   - In IoT Hub, go to IoT Edge → your device
   - Click **"Set Modules"**
   - Upload the deployment manifest or configure modules manually

### Step 5: Local Storage and Offline Scenarios

#### Create Local Storage Module

1. **Local Storage Dockerfile**:
   ```dockerfile
   FROM mcr.microsoft.com/azureiotedge-module-base:1.0-linux-amd64
   
   RUN apt-get update && apt-get install -y \
       sqlite3 \
       python3 \
       python3-pip
   
   COPY requirements.txt ./
   RUN pip3 install -r requirements.txt
   
   COPY . .
   
   CMD ["python3", "main.py"]
   ```

2. **Local Storage Python Module**:
   ```python
   import asyncio
   import json
   import sqlite3
   import logging
   from azure.iot.device.aio import IoTHubModuleClient
   from datetime import datetime
   
   class LocalStorageModule:
       def __init__(self):
           self.client = None
           self.init_database()
   
       def init_database(self):
           """Initialize SQLite database for local storage"""
           self.conn = sqlite3.connect('/data/telemetry.db', check_same_thread=False)
           cursor = self.conn.cursor()
           cursor.execute('''
               CREATE TABLE IF NOT EXISTS telemetry (
                   id INTEGER PRIMARY KEY AUTOINCREMENT,
                   timestamp TEXT,
                   device_id TEXT,
                   temperature REAL,
                   humidity REAL,
                   pressure REAL,
                   processed_at TEXT,
                   sent_to_cloud BOOLEAN DEFAULT FALSE
               )
           ''')
           self.conn.commit()
   
       async def store_message(self, message):
           """Store incoming message to local database"""
           try:
               data = json.loads(message.data)
               cursor = self.conn.cursor()
               cursor.execute('''
                   INSERT INTO telemetry 
                   (timestamp, device_id, temperature, humidity, pressure, processed_at)
                   VALUES (?, ?, ?, ?, ?, ?)
               ''', (
                   data.get('timestamp'),
                   data.get('deviceId'),
                   data.get('temperature'),
                   data.get('humidity'),
                   data.get('pressure'),
                   datetime.utcnow().isoformat()
               ))
               self.conn.commit()
               logging.info(f"Stored message locally: {data.get('deviceId')}")
           except Exception as e:
               logging.error(f"Error storing message: {e}")
   
       async def sync_to_cloud(self):
           """Periodically sync unsent data to cloud when connection is available"""
           try:
               cursor = self.conn.cursor()
               cursor.execute('''
                   SELECT * FROM telemetry WHERE sent_to_cloud = FALSE LIMIT 100
               ''')
               unsent_data = cursor.fetchall()
               
               for row in unsent_data:
                   message_data = {
                       "timestamp": row[1],
                       "deviceId": row[2],
                       "temperature": row[3],
                       "humidity": row[4],
                       "pressure": row[5],
                       "processed_at": row[6],
                       "sync_type": "edge_sync"
                   }
                   
                   # Send to cloud
                   await self.client.send_message_to_output(
                       json.dumps(message_data), "cloud-sync"
                   )
                   
                   # Mark as sent
                   cursor.execute('''
                       UPDATE telemetry SET sent_to_cloud = TRUE WHERE id = ?
                   ''', (row[0],))
               
               self.conn.commit()
               logging.info(f"Synced {len(unsent_data)} messages to cloud")
               
           except Exception as e:
               logging.error(f"Error syncing to cloud: {e}")
   
       async def main(self):
           """Main module logic"""
           try:
               self.client = IoTHubModuleClient.create_from_edge_environment()
               await self.client.connect()
               
               # Set message handler
               self.client.on_message_received = self.store_message
               
               # Periodic sync task
               async def sync_task():
                   while True:
                       await asyncio.sleep(300)  # Sync every 5 minutes
                       await self.sync_to_cloud()
               
               await asyncio.gather(
                   self.client.receive_message_from_input("input1"),
                   sync_task()
               )
               
           except Exception as e:
               logging.error(f"Module error: {e}")
           finally:
               await self.client.disconnect()
   
   if __name__ == "__main__":
       logging.basicConfig(level=logging.INFO)
       module = LocalStorageModule()
       asyncio.run(module.main())
   ```

### Step 6: Edge Device Management and Monitoring

#### Monitor Edge Device Health
```sql
-- Query to monitor edge device connectivity and health
SELECT 
    deviceId,
    System.Timestamp() AS lastSeen,
    COUNT(*) AS messageCount,
    AVG(temperature) AS avgTemp,
    'EDGE_HEALTH_REPORT' AS messageType
INTO [edge-monitoring]
FROM [edge-input]
GROUP BY deviceId, TumblingWindow(minute, 10)
```

#### Edge Device Diagnostics Module
```python
import psutil
import json
import asyncio
from azure.iot.device.aio import IoTHubModuleClient

class EdgeDiagnosticsModule:
    async def send_diagnostics(self, client):
        """Send edge device diagnostics to cloud"""
        while True:
            try:
                diagnostics = {
                    "timestamp": datetime.utcnow().isoformat(),
                    "deviceId": "edge-device-01",
                    "cpu_percent": psutil.cpu_percent(interval=1),
                    "memory_percent": psutil.virtual_memory().percent,
                    "disk_percent": psutil.disk_usage('/').percent,
                    "temperature": self.get_cpu_temperature(),
                    "network_bytes_sent": psutil.net_io_counters().bytes_sent,
                    "network_bytes_recv": psutil.net_io_counters().bytes_recv,
                    "edge_runtime_status": "running",
                    "modules_running": self.count_running_modules()
                }
                
                await client.send_message_to_output(
                    json.dumps(diagnostics), "diagnostics"
                )
                
                await asyncio.sleep(60)  # Send every minute
                
            except Exception as e:
                print(f"Error sending diagnostics: {e}")
                await asyncio.sleep(60)
```

### Step 7: Security Best Practices

#### Device Certificate Management
```python
# Example of secure certificate-based authentication
from azure.iot.device.aio import IoTHubModuleClient
from azure.iot.device import X509

class SecureEdgeModule:
    def __init__(self):
        # Use X.509 certificates for enhanced security
        x509 = X509(
            cert_file="/etc/iotedge/device_cert.pem",
            key_file="/etc/iotedge/device_key.pem",
            pass_phrase="your_passphrase"
        )
        
        self.client = IoTHubModuleClient.create_from_x509_certificate(
            x509=x509,
            hostname="your-iothub.azure-devices.net",
            device_id="edge-device-01",
            module_id="SecureModule"
        )
```

#### Secure Data Transmission
```sql
-- Encrypt sensitive data before sending to cloud
SELECT 
    deviceId,
    timestamp,
    UDF.encrypt(temperature) AS encryptedTemperature,
    UDF.hash(deviceId) AS hashedDeviceId,
    'ENCRYPTED_TELEMETRY' AS dataType
INTO [secure-output]
FROM [edge-input]
WHERE temperature > 30  -- Only send sensitive readings
```

### Step 8: Performance Optimization

#### Edge Query Optimization
```sql
-- Optimized query for edge processing
WITH FilteredData AS (
    SELECT *
    FROM [edge-input]
    WHERE temperature IS NOT NULL 
      AND timestamp > DATEADD(minute, -30, System.Timestamp())
),
ProcessedData AS (
    SELECT 
        deviceId,
        timestamp,
        temperature,
        -- Use window functions efficiently
        LAG(temperature) OVER (PARTITION BY deviceId ORDER BY timestamp) AS prevTemp,
        AVG(temperature) OVER (
            PARTITION BY deviceId 
            ORDER BY timestamp 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS smoothedTemp
    FROM FilteredData
)
SELECT 
    deviceId,
    timestamp,
    smoothedTemp AS temperature,
    ABS(temperature - prevTemp) AS tempChange,
    CASE 
        WHEN ABS(temperature - prevTemp) > 5 THEN 'RAPID_CHANGE'
        WHEN smoothedTemp > 35 THEN 'HIGH_TEMP'
        ELSE 'NORMAL'
    END AS status
INTO [edge-output]
FROM ProcessedData
WHERE ABS(temperature - prevTemp) > 1  -- Only send when there's meaningful change
```

## 🔧 Testing and Validation

### Step 9: Test Edge Deployment

1. **Validate Module Deployment**:
   ```bash
   # Check running modules
   sudo iotedge list
   
   # Check module logs
   sudo iotedge logs StreamAnalyticsModule
   sudo iotedge logs SimulatedTemperatureSensor
   ```

2. **Test Offline Scenarios**:
   ```bash
   # Simulate network disconnection
   sudo iptables -A OUTPUT -p tcp --dport 443 -j DROP
   sudo iptables -A OUTPUT -p tcp --dport 5671 -j DROP
   
   # Verify local storage continues working
   # Restore connectivity and verify sync
   sudo iptables -F
   ```

3. **Monitor Edge Performance**:
   ```bash
   # Monitor resource usage
   docker stats
   
   # Check edge hub message routing
   sudo iotedge logs edgeHub
   ```

## 📊 Monitoring and Troubleshooting

### Common Edge Issues:

1. **Module Won't Start**:
   - Check container logs: `sudo iotedge logs [module-name]`
   - Verify image pull: `docker images`
   - Check deployment manifest syntax

2. **Messages Not Flowing**:
   - Verify route configuration in edgeHub
   - Check message format compatibility
   - Monitor edgeHub logs for routing errors

3. **High Resource Usage**:
   - Optimize queries to reduce processing
   - Implement data sampling
   - Monitor container resource limits

### Performance Monitoring Query:
```sql
-- Monitor edge processing performance
SELECT 
    System.Timestamp() AS timestamp,
    COUNT(*) AS messagesProcessed,
    AVG(DATEDIFF(millisecond, timestamp, System.Timestamp())) AS avgProcessingLatency,
    'EDGE_PERFORMANCE' AS metricType
INTO [edge-monitoring]
FROM [edge-input]
GROUP BY TumblingWindow(minute, 1)
```

## 💡 Best Practices

### Edge Processing Strategy:
1. **Filter First**: Remove unnecessary data at the edge
2. **Aggregate Smart**: Reduce bandwidth with intelligent summarization
3. **Store Locally**: Handle connectivity issues gracefully
4. **Prioritize Critical**: Send alerts immediately, batch non-critical data
5. **Monitor Health**: Track edge device and module performance

### Security Considerations:
1. **Use Certificate Authentication**: More secure than symmetric keys
2. **Encrypt Sensitive Data**: Protect data in transit and at rest
3. **Regular Updates**: Keep edge runtime and modules updated
4. **Network Isolation**: Use firewalls and VPNs for edge networks
5. **Audit Access**: Monitor and log edge device access

## 🎯 Success Criteria

✅ IoT Edge runtime successfully installed and running  
✅ Stream Analytics module deployed and processing data  
✅ Local data filtering and aggregation working  
✅ Offline scenarios handled with local storage  
✅ Cloud synchronization working when connectivity restored  
✅ Edge device monitoring and diagnostics implemented  
✅ Security best practices applied  

## 📈 Cost Considerations

### Edge vs Cloud Processing:
- **Edge Hardware**: $500-5000+ per device depending on requirements
- **Connectivity**: Reduced bandwidth costs (70-90% reduction typical)
- **Cloud Processing**: Reduced Stream Analytics Units needed
- **Maintenance**: Additional operational overhead for edge devices
- **Total Cost**: Often 30-50% reduction for distributed IoT scenarios

### ROI Factors:
- **Latency Reduction**: Real-time responses for critical scenarios
- **Bandwidth Savings**: Significant for high-volume, low-value data
- **Reliability**: Continued operation during connectivity issues
- **Compliance**: Data residency and privacy requirements

## 🔄 Edge to Cloud Migration Strategy

### Gradual Migration Approach:
1. **Phase 1**: Deploy edge for critical/latency-sensitive processing
2. **Phase 2**: Move non-critical aggregation to edge
3. **Phase 3**: Implement comprehensive edge analytics
4. **Phase 4**: Optimize cloud resources based on reduced load

### Hybrid Architecture Benefits:
- **Best of Both Worlds**: Edge for real-time, cloud for complex analytics
- **Scalability**: Cloud resources for heavy computation
- **Flexibility**: Dynamic workload distribution
- **Cost Optimization**: Process locally when cheaper, use cloud for scale

## 🎓 Conclusion

This lab demonstrated how Azure IoT Edge extends cloud analytics capabilities to edge devices, enabling:
- **Real-time Processing**: Immediate responses to critical conditions
- **Bandwidth Optimization**: Intelligent data filtering and aggregation
- **Offline Resilience**: Continued operation during connectivity issues
- **Distributed Architecture**: Optimal placement of processing workloads

The combination of cloud and edge processing provides a powerful, flexible, and cost-effective solution for modern IoT scenarios.

## 🔗 Workshop Completion

Congratulations! You have completed the Azure Stream Analytics Workshop. You've learned:
- Stream Analytics fundamentals and advanced features
- Real-time analytics and anomaly detection
- Power BI integration for visualization
- Microsoft Fabric Real-Time Intelligence
- IoT Edge computing scenarios

**Next Steps**:
- Implement these patterns in your own IoT solutions
- Explore advanced features like custom user-defined functions
- Consider hybrid cloud-edge architectures for your use cases
- Continue learning with Azure IoT and analytics services
