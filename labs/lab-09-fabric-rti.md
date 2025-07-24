# Lab 9: Microsoft Fabric Real-Time Intelligence (RTI) Overview

## 🎯 Lab Objectives

In this lab, you will:
- Understand Microsoft Fabric Real-Time Intelligence capabilities
- Compare Azure Stream Analytics with Fabric RTI
- Set up Fabric Real-Time Intelligence workspace
- Create KQL databases and tables for streaming data
- Implement real-time data ingestion with Event Streams
- Build KQL queries for real-time analytics
- Create real-time dashboards in Fabric
- Understand migration strategies from Stream Analytics to Fabric RTI

## 📋 Prerequisites

- Completed [Lab 7: Real-time Power BI Visualization](./lab-07-powerbi-visualization.md)
- Microsoft Fabric workspace access (Trial or Premium capacity)
- Understanding of Azure Stream Analytics concepts
- Basic familiarity with KQL (Kusto Query Language) - optional
- Event Hub with streaming telemetry data

## 🔄 Fabric RTI vs Stream Analytics Comparison

| Feature | Azure Stream Analytics | Microsoft Fabric RTI |
|---------|----------------------|----------------------|
| **Query Language** | Stream Analytics Query Language (SAQL) | Kusto Query Language (KQL) |
| **Data Storage** | Pass-through processing | Native storage in KQL databases |
| **Scalability** | Streaming Units (1-200+) | Automatic scaling |
| **Analytics** | Stream processing + basic ML | Advanced analytics + AI/ML integration |
| **Visualization** | External (Power BI, custom) | Integrated dashboards + Power BI |
| **Cost Model** | Pay per Streaming Unit | Pay per compute + storage consumption |
| **Development** | Azure Portal/VS Code | Fabric workspace environment |
| **Data Retention** | Limited (outputs to storage) | Native time-series storage |

## 🏗️ Architecture Overview

```
[Event Hub] → [Fabric Event Streams] → [KQL Database] → [Real-time Dashboard]
                        ↓                    ↓               ↓
                 [Data Transformation]  [Hot/Cold Storage]  [Power BI Integration]
```

## 📝 Step-by-Step Instructions

### Step 1: Set Up Microsoft Fabric RTI Workspace

1. **Access Microsoft Fabric**:
   - Navigate to [app.fabric.microsoft.com](https://app.fabric.microsoft.com)
   - Sign in with your Microsoft account
   - Ensure you have Fabric capacity or start a trial

2. **Create RTI Workspace**:
   - Click **"+ New workspace"**
   - Name: `RTI-IoT-Analytics`
   - Description: `Real-time IoT analytics with Fabric RTI`
   - Select **"Trial"** or assign Premium capacity

3. **Switch to Real-Time Intelligence Experience**:
   - In the bottom-left, click the experience switcher
   - Select **"Real-Time Intelligence"**

### Step 2: Create KQL Database

1. **Create KQL Database**:
   - Click **"+ New"** → **"KQL Database"**
   - Name: `IoTTelemetryDB`
   - Confirm creation and wait for provisioning

2. **Create Tables for Telemetry Data**:
   ```kql
   // Create main telemetry table
   .create table TelemetryData (
       Timestamp: datetime,
       DeviceId: string,
       Temperature: real,
       Humidity: real,
       Pressure: real,
       Latitude: real,
       Longitude: real,
       MessageId: string,
       EventProcessedUtcTime: datetime,
       PartitionId: int,
       EventEnqueuedUtcTime: datetime
   )
   ```

3. **Create Additional Tables for Analytics**:
   ```kql
   // Create aggregated metrics table
   .create table DeviceMetrics (
       WindowStart: datetime,
       WindowEnd: datetime,
       DeviceId: string,
       AvgTemperature: real,
       MinTemperature: real,
       MaxTemperature: real,
       AvgHumidity: real,
       AvgPressure: real,
       EventCount: long
   )
   
   // Create anomaly detection results table
   .create table AnomalyResults (
       Timestamp: datetime,
       DeviceId: string,
       Temperature: real,
       AnomalyScore: real,
       IsAnomaly: bool,
       AnomalyType: string
   )
   ```

### Step 3: Set Up Data Ingestion with Event Streams

1. **Create Event Stream**:
   - In your RTI workspace, click **"+ New"** → **"Event Stream"**
   - Name: `IoT-Telemetry-Stream`

2. **Configure Event Hub Source**:
   - In the Event Stream canvas, click **"Add source"**
   - Select **"Event Hub"**
   - Configure connection:
     ```
     Event Hub namespace: [Your Event Hub namespace]
     Event Hub name: telemetry-data
     Consumer group: $Default
     Authentication: Connection string
     ```

3. **Add Data Transformation** (Optional):
   - Click **"Transform events"** if you need to modify data structure
   - Use the visual editor or custom code for transformations

4. **Configure KQL Database Destination**:
   - Click **"Add destination"** → **"KQL Database"**
   - Select your `IoTTelemetryDB`
   - Target table: `TelemetryData`
   - Configure data mapping

### Step 4: Real-time Analytics with KQL

#### Query 1: Basic Data Exploration
```kql
// Explore recent telemetry data
TelemetryData
| where Timestamp > ago(1h)
| take 100
| project Timestamp, DeviceId, Temperature, Humidity, Pressure
| order by Timestamp desc
```

#### Query 2: Real-time Device Monitoring
```kql
// Current status of all devices (last reading per device)
TelemetryData
| where Timestamp > ago(15m)
| summarize arg_max(Timestamp, *) by DeviceId
| project DeviceId, Timestamp, Temperature, Humidity, Pressure,
    Status = case(
        Temperature > 35 or Temperature < 5, "Critical",
        Temperature > 30 or Temperature < 10, "Warning", 
        "Normal"
    )
| order by Status desc, Timestamp desc
```

#### Query 3: Time Series Analysis with Binning
```kql
// Temperature trends over time with 5-minute intervals
TelemetryData
| where Timestamp > ago(6h)
| summarize 
    AvgTemp = avg(Temperature),
    MinTemp = min(Temperature),
    MaxTemp = max(Temperature),
    DeviceCount = dcount(DeviceId)
    by bin(Timestamp, 5m)
| order by Timestamp desc
| render timechart with (title="Temperature Trends (5-min intervals)")
```

#### Query 4: Anomaly Detection with KQL
```kql
// Detect temperature anomalies using statistical methods
let temperatureStats = TelemetryData
| where Timestamp > ago(24h)
| summarize 
    AvgTemp = avg(Temperature),
    StdTemp = stdev(Temperature)
    by DeviceId;
TelemetryData
| where Timestamp > ago(1h)
| join kind=inner temperatureStats on DeviceId
| extend 
    ZScore = abs(Temperature - AvgTemp) / StdTemp,
    IsAnomaly = abs(Temperature - AvgTemp) / StdTemp > 2.5
| where IsAnomaly == true
| project Timestamp, DeviceId, Temperature, AvgTemp, ZScore
| order by ZScore desc
```

#### Query 5: Geographic Analysis
```kql
// Device distribution and temperature by location
TelemetryData
| where Timestamp > ago(1h) and isnotnull(Latitude) and isnotnull(Longitude)
| summarize 
    AvgTemp = avg(Temperature),
    MaxTemp = max(Temperature),
    MinTemp = min(Temperature),
    LastUpdate = max(Timestamp)
    by DeviceId, Latitude, Longitude
| extend LocationKey = strcat(round(Latitude, 2), "_", round(Longitude, 2))
| summarize 
    DeviceCount = count(),
    AvgTemperature = avg(AvgTemp),
    MaxTemperature = max(MaxTemp)
    by LocationKey, Latitude = round(Latitude, 2), Longitude = round(Longitude, 2)
```

### Step 5: Advanced Analytics and ML Integration

#### Query 6: Predictive Analytics with Time Series Functions
```kql
// Predict next hour temperature using linear regression
TelemetryData
| where Timestamp > ago(6h)
| make-series Temperature = avg(Temperature) on Timestamp step 10m by DeviceId
| extend (RSquare, Slope, Variance, RVariance, Interception, LineFit) = series_fit_line(Temperature)
| extend NextHourPrediction = Interception + Slope * (array_length(Temperature) + 6) // 6 * 10min = 1 hour
| project DeviceId, RSquare, Slope, NextHourPrediction
| where RSquare > 0.7  // Only include devices with good fit
```

#### Query 7: Pattern Detection
```kql
// Detect repeating patterns in temperature data
TelemetryData
| where Timestamp > ago(24h)
| make-series Temperature = avg(Temperature) on Timestamp step 1h by DeviceId
| extend Pattern = series_seasonal_decompose(Temperature, 24)  // 24-hour pattern
| extend 
    Trend = Pattern.trend,
    Seasonal = Pattern.seasonal,
    Residual = Pattern.residual
| project DeviceId, Trend, Seasonal, Residual
```

### Step 6: Create Real-time Dashboards

1. **Create New Dashboard**:
   - In Fabric workspace, click **"+ New"** → **"Real-Time Dashboard"**
   - Name: `IoT Telemetry Dashboard`

2. **Add Tiles with KQL Queries**:

   **a) Device Count Tile**:
   ```kql
   TelemetryData
   | where Timestamp > ago(5m)
   | dcount(DeviceId)
   ```

   **b) Average Temperature Gauge**:
   ```kql
   TelemetryData
   | where Timestamp > ago(5m)
   | summarize AvgTemp = avg(Temperature)
   | project AvgTemp
   ```

   **c) Temperature Time Series**:
   ```kql
   TelemetryData
   | where Timestamp > ago(2h)
   | summarize AvgTemperature = avg(Temperature) by bin(Timestamp, 2m)
   | render timechart
   ```

   **d) Geographic Heat Map**:
   ```kql
   TelemetryData
   | where Timestamp > ago(15m) and isnotnull(Latitude) and isnotnull(Longitude)
   | summarize AvgTemp = avg(Temperature) by DeviceId, Latitude, Longitude
   | project Longitude, Latitude, AvgTemp
   ```

3. **Configure Auto-refresh**:
   - Set dashboard auto-refresh to 30 seconds
   - Configure individual tile refresh rates as needed

### Step 7: Advanced Data Processing

#### Query 8: Continuous Aggregation with Update Policies
```kql
// Create function for aggregation
.create function DeviceAggregationFunction() {
    TelemetryData
    | summarize 
        AvgTemperature = avg(Temperature),
        MinTemperature = min(Temperature),
        MaxTemperature = max(Temperature),
        AvgHumidity = avg(Humidity),
        AvgPressure = avg(Pressure),
        EventCount = count()
        by WindowStart = bin(Timestamp, 5m), DeviceId
    | extend WindowEnd = WindowStart + 5m
}

// Create update policy for automatic aggregation
.alter table DeviceMetrics policy update @'[{"Source": "TelemetryData", "Query": "DeviceAggregationFunction()", "IsEnabled": "True"}]'
```

#### Query 9: Real-time Alerting with KQL
```kql
// Create alert query for temperature anomalies
TelemetryData
| where Timestamp > ago(5m)
| where Temperature > 40 or Temperature < 0
| project Timestamp, DeviceId, Temperature, 
    AlertType = case(Temperature > 40, "HIGH_TEMP", "LOW_TEMP"),
    Severity = case(Temperature > 45 or Temperature < -5, "CRITICAL", "WARNING")
| summarize AlertCount = count() by AlertType, Severity
```

### Step 8: Migration Strategy from Stream Analytics

#### Migration Planning Checklist:

1. **Query Translation**:
   - **SAQL → KQL Mapping**:
     ```
     SELECT → project
     FROM → (implicit in KQL)
     WHERE → where
     GROUP BY → summarize ... by
     WINDOW functions → bin() or make-series
     JOIN → join
     ```

2. **Sample Migration Example**:
   
   **Original Stream Analytics Query**:
   ```sql
   SELECT 
       System.Timestamp() AS WindowEnd,
       deviceId,
       AVG(temperature) AS AvgTemperature,
       COUNT(*) AS EventCount
   FROM [input]
   GROUP BY deviceId, TumblingWindow(minute, 5)
   ```

   **Equivalent KQL Query**:
   ```kql
   TelemetryData
   | summarize 
       AvgTemperature = avg(Temperature),
       EventCount = count()
       by DeviceId, WindowEnd = bin(Timestamp, 5m)
   ```

3. **Data Flow Migration**:
   - Replace Stream Analytics outputs with KQL database ingestion
   - Update downstream consumers to query KQL database
   - Implement data retention policies in KQL

## 🔧 Testing and Validation

### Step 9: Performance Testing

1. **Query Performance**:
   ```kql
   // Test query performance with explain
   TelemetryData
   | where Timestamp > ago(1h)
   | summarize count() by DeviceId
   | explain
   ```

2. **Ingestion Rate Monitoring**:
   ```kql
   // Monitor ingestion rate
   .show ingestion failures
   
   // Check ingestion statistics
   .show table TelemetryData ingestion statistics
   ```

3. **Resource Usage**:
   ```kql
   // Monitor cluster resource usage
   .show cluster
   .show capacity
   ```

## 📊 Advanced Features

### Data Management:

1. **Data Retention Policies**:
   ```kql
   // Set 90-day retention policy
   .alter table TelemetryData policy retention softdelete = 90d
   ```

2. **Data Partitioning**:
   ```kql
   // Partition by device for better performance
   .alter table TelemetryData policy partitioning @'{"PartitionKeys":[{"ColumnName":"DeviceId","Kind":"Hash","Properties":{"Function":"XxHash64","MaxPartitionCount":256}}]}'
   ```

3. **Data Compression**:
   ```kql
   // Enable compression
   .alter table TelemetryData policy encoding type='gzip'
   ```

## 🚨 Common Issues and Troubleshooting

### Issue 1: Data Ingestion Delays
**Solutions**:
- Check Event Hub connection settings
- Verify data mapping configuration
- Monitor ingestion failures table

### Issue 2: Query Performance Issues
**Solutions**:
- Add appropriate indexes
- Optimize time range filters
- Use summarization instead of raw data queries

### Issue 3: Dashboard Loading Slowly
**Solutions**:
- Reduce query time ranges
- Use cached results where possible
- Optimize KQL queries for dashboard consumption

## 💡 Best Practices

1. **Query Optimization**:
   - Always filter by time first
   - Use summarization for aggregated views
   - Leverage table partitioning
   - Cache frequently used results

2. **Data Modeling**:
   - Design tables for your query patterns
   - Use appropriate data types
   - Implement proper retention policies
   - Consider hot/cold storage tiers

3. **Performance Monitoring**:
   - Monitor ingestion rates and failures
   - Track query performance metrics
   - Set up alerts for system health
   - Regular capacity planning

4. **Security and Governance**:
   - Implement row-level security if needed
   - Use managed identities for authentication
   - Set up proper RBAC permissions
   - Monitor data access patterns

## 🎯 Success Criteria

✅ Successfully ingested streaming data into KQL database  
✅ Created real-time dashboard with live tiles  
✅ Implemented anomaly detection using KQL  
✅ Set up automated data aggregation  
✅ Configured alerting for critical conditions  
✅ Optimized queries for performance  
✅ Established data retention policies  

## 📈 Cost Considerations

- **Fabric Capacity**: $8,000-20,000/month for Premium capacity (shared across all Fabric workloads)
- **Data Storage**: Included in capacity, additional costs for long-term retention
- **Compute**: Included in capacity, scales automatically
- **Data Transfer**: Minimal for Event Hub to Fabric ingestion
- **Power BI**: Included with Fabric Premium

**Note**: Fabric RTI uses a capacity-based model rather than per-resource pricing like Stream Analytics.

## 🔗 Next Steps

Continue to [Lab 10: IoT Edge Overview](./lab-10-iot-edge.md) to learn about edge computing scenarios and bringing analytics closer to your IoT devices.
