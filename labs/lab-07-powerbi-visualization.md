# Lab 7: Real-time Power BI Visualization

## 🎯 Lab Objectives

In this lab, you will:
- Configure Power BI as a Stream Analytics output
- Create real-time streaming datasets in Power BI
- Build live dashboards with automatic refresh
- Implement tiles for different visualization types
- Handle streaming data limitations and best practices
- Create alerts and notifications in Power BI
- Optimize dashboard performance for real-time data

## 📋 Prerequisites

- Completed [Lab 6: Analytics Functions](./lab-06-analytics-functions.md)
- Power BI Pro or Premium license
- Power BI account with workspace access
- Stream Analytics job with input data flowing
- Understanding of Power BI basics (optional but helpful)

## 🎨 Architecture Overview

```
[Event Hub] → [Stream Analytics] → [Power BI Dataset] → [Real-time Dashboard]
                     ↓
               [Alert Rules] → [Email/Teams Notifications]
```

## 📝 Step-by-Step Instructions

### Step 1: Configure Power BI Output in Stream Analytics

1. **Add Power BI Output**:
   - Navigate to your Stream Analytics job
   - Go to **"Outputs"** in the left menu
   - Click **"+ Add"** → **"Power BI"**

2. **Configure Power BI Connection**:
   ```
   Output alias: powerbi-dashboard
   Group workspace: [Select your workspace]
   Authentication mode: User token
   Dataset name: telemetry-realtime
   Table name: sensor-data
   ```

3. **Authorize Connection**:
   - Click **"Authorize"** to connect to Power BI
   - Sign in with your Power BI account
   - Grant necessary permissions

### Step 2: Create Basic Real-time Query

#### Query 1: Real-time Device Telemetry
```sql
-- Basic telemetry data for Power BI visualization
SELECT 
    deviceId,
    System.Timestamp() AS timestamp,
    temperature,
    humidity,
    pressure,
    location.lat AS latitude,
    location.lon AS longitude,
    -- Add calculated fields for better visualization
    CASE 
        WHEN temperature > 30 THEN 'Hot'
        WHEN temperature < 10 THEN 'Cold'
        ELSE 'Normal'
    END AS temperatureCategory,
    CASE 
        WHEN humidity > 80 THEN 'High'
        WHEN humidity < 30 THEN 'Low'
        ELSE 'Normal'
    END AS humidityCategory
INTO [powerbi-dashboard]
FROM [telemetry-input] TIMESTAMP BY timestamp
```

#### Query 2: Aggregated Metrics for Real-time KPIs
```sql
-- 1-minute aggregated metrics for KPI tiles
SELECT 
    System.Timestamp() AS windowEnd,
    COUNT(*) AS totalEvents,
    COUNT(DISTINCT deviceId) AS activeDevices,
    AVG(temperature) AS avgTemperature,
    MIN(temperature) AS minTemperature,
    MAX(temperature) AS maxTemperature,
    AVG(humidity) AS avgHumidity,
    AVG(pressure) AS avgPressure,
    -- Temperature distribution
    SUM(CASE WHEN temperature > 30 THEN 1 ELSE 0 END) AS hotDevices,
    SUM(CASE WHEN temperature < 10 THEN 1 ELSE 0 END) AS coldDevices,
    SUM(CASE WHEN temperature BETWEEN 10 AND 30 THEN 1 ELSE 0 END) AS normalDevices,
    -- Alert conditions
    SUM(CASE WHEN temperature > 35 OR temperature < 5 THEN 1 ELSE 0 END) AS criticalAlerts,
    SUM(CASE WHEN humidity > 90 OR humidity < 20 THEN 1 ELSE 0 END) AS humidityAlerts
INTO [powerbi-dashboard]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY TumblingWindow(minute, 1)
```

### Step 3: Advanced Visualization Queries

#### Query 3: Device Health Dashboard
```sql
-- Device health metrics with status indicators
WITH DeviceMetrics AS (
    SELECT 
        deviceId,
        System.Timestamp() AS timestamp,
        temperature,
        humidity,
        pressure,
        -- Calculate device health score (0-100)
        CASE 
            WHEN temperature BETWEEN 15 AND 28 AND humidity BETWEEN 30 AND 70 THEN 100
            WHEN temperature BETWEEN 10 AND 35 AND humidity BETWEEN 20 AND 80 THEN 80
            WHEN temperature BETWEEN 5 AND 40 AND humidity BETWEEN 15 AND 85 THEN 60
            WHEN temperature BETWEEN 0 AND 45 AND humidity BETWEEN 10 AND 90 THEN 40
            ELSE 20
        END AS healthScore,
        -- Last seen timestamp for connectivity monitoring
        LAG(System.Timestamp()) OVER (PARTITION BY deviceId ORDER BY System.Timestamp()) AS previousTimestamp
    FROM [telemetry-input] TIMESTAMP BY timestamp
),
DeviceStatus AS (
    SELECT 
        deviceId,
        timestamp,
        temperature,
        humidity,
        pressure,
        healthScore,
        -- Connection status
        CASE 
            WHEN DATEDIFF(minute, previousTimestamp, timestamp) > 5 THEN 'Reconnected'
            WHEN DATEDIFF(minute, previousTimestamp, timestamp) > 2 THEN 'Intermittent'
            ELSE 'Connected'
        END AS connectionStatus,
        -- Overall device status
        CASE 
            WHEN healthScore >= 80 THEN 'Healthy'
            WHEN healthScore >= 60 THEN 'Warning'
            WHEN healthScore >= 40 THEN 'Critical'
            ELSE 'Failure'
        END AS deviceStatus
    FROM DeviceMetrics
)
SELECT 
    deviceId,
    timestamp,
    temperature,
    humidity,
    pressure,
    healthScore,
    connectionStatus,
    deviceStatus,
    -- Additional metrics for visualization
    CAST(deviceId AS VARCHAR) + ' (' + deviceStatus + ')' AS deviceLabel,
    -- Color coding for Power BI conditional formatting
    CASE deviceStatus
        WHEN 'Healthy' THEN '#00FF00'
        WHEN 'Warning' THEN '#FFA500'
        WHEN 'Critical' THEN '#FF6347'
        WHEN 'Failure' THEN '#FF0000'
    END AS statusColor
INTO [powerbi-dashboard]
FROM DeviceStatus
```

#### Query 4: Geographic Heat Map Data
```sql
-- Geographic data for Power BI map visualizations
SELECT 
    location.lat AS latitude,
    location.lon AS longitude,
    deviceId,
    System.Timestamp() AS timestamp,
    temperature,
    humidity,
    pressure,
    -- Temperature intensity for heat map
    CASE 
        WHEN temperature > 35 THEN 10
        WHEN temperature > 30 THEN 8
        WHEN temperature > 25 THEN 6
        WHEN temperature > 20 THEN 4
        WHEN temperature > 15 THEN 2
        ELSE 1
    END AS temperatureIntensity,
    -- Humidity intensity
    CASE 
        WHEN humidity > 80 THEN 10
        WHEN humidity > 70 THEN 8
        WHEN humidity > 60 THEN 6
        WHEN humidity > 50 THEN 4
        WHEN humidity > 40 THEN 2
        ELSE 1
    END AS humidityIntensity,
    -- Location-based aggregation key for clustering
    CONCAT(
        CAST(FLOOR(location.lat * 100) AS VARCHAR), 
        '_', 
        CAST(FLOOR(location.lon * 100) AS VARCHAR)
    ) AS locationCluster
INTO [powerbi-dashboard]
FROM [telemetry-input] TIMESTAMP BY timestamp
WHERE location.lat IS NOT NULL AND location.lon IS NOT NULL
```

#### Query 5: Time Series Analysis for Trending
```sql
-- Time series data optimized for Power BI line charts
WITH TimeSeriesData AS (
    SELECT 
        System.Timestamp() AS timestamp,
        deviceId,
        temperature,
        humidity,
        pressure,
        -- Moving averages for smooth trending
        AVG(temperature) OVER (
            PARTITION BY deviceId 
            ORDER BY System.Timestamp() 
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS temperature5MinAvg,
        AVG(humidity) OVER (
            PARTITION BY deviceId 
            ORDER BY System.Timestamp() 
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS humidity5MinAvg,
        -- Deviation from moving average
        temperature - AVG(temperature) OVER (
            PARTITION BY deviceId 
            ORDER BY System.Timestamp() 
            ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
        ) AS temperatureDeviation
    FROM [telemetry-input] TIMESTAMP BY timestamp
)
SELECT 
    timestamp,
    deviceId,
    temperature,
    humidity,
    pressure,
    temperature5MinAvg,
    humidity5MinAvg,
    temperatureDeviation,
    -- Trend indicators
    CASE 
        WHEN temperatureDeviation > 2 THEN 'Rising'
        WHEN temperatureDeviation < -2 THEN 'Falling'
        ELSE 'Stable'
    END AS temperatureTrend,
    -- Time components for Power BI time intelligence
    DATEPART(hour, timestamp) AS hourOfDay,
    DATEPART(dayofweek, timestamp) AS dayOfWeek,
    DATEPART(minute, timestamp) AS minuteOfHour
INTO [powerbi-dashboard]
FROM TimeSeriesData
```

### Step 4: Create Power BI Dashboard

1. **Access Power BI Service**:
   - Go to [PowerBI.com](https://powerbi.com)
   - Navigate to your workspace
   - Find the `telemetry-realtime` dataset

2. **Create New Dashboard**:
   - Click **"+ New"** → **"Dashboard"**
   - Name it: `IoT Telemetry Real-time Dashboard`

3. **Add KPI Tiles**:

   **a) Total Active Devices**:
   ```
   Visualization: Card
   Field: activeDevices (latest value)
   Title: "Active Devices"
   ```

   **b) Average Temperature**:
   ```
   Visualization: Gauge
   Value: avgTemperature
   Minimum: 0
   Maximum: 50
   Target: 22
   Title: "Avg Temperature (°C)"
   ```

   **c) Critical Alerts Count**:
   ```
   Visualization: Card
   Field: criticalAlerts
   Conditional Formatting: Red if > 0
   Title: "Critical Alerts"
   ```

4. **Add Chart Visualizations**:

   **a) Temperature Over Time**:
   ```
   Visualization: Line Chart
   Axis: timestamp
   Values: temperature, temperature5MinAvg
   Legend: deviceId
   Title: "Temperature Trends"
   ```

   **b) Device Status Distribution**:
   ```
   Visualization: Donut Chart
   Legend: deviceStatus
   Values: Count of deviceId
   Colors: Custom (Green=Healthy, Orange=Warning, Red=Critical)
   Title: "Device Health Status"
   ```

   **c) Geographic Heat Map**:
   ```
   Visualization: Map
   Location: latitude, longitude
   Size: temperatureIntensity
   Color: temperature
   Title: "Temperature Heat Map"
   ```

### Step 5: Advanced Dashboard Features

#### Query 6: Anomaly Detection Integration
```sql
-- Combine anomaly detection with Power BI visualization
WITH AnomalyData AS (
    SELECT 
        deviceId,
        System.Timestamp() AS timestamp,
        temperature,
        humidity,
        pressure,
        ANOMALYDETECTION_SPIKEANDDIP(temperature, 90, 120, 'spikesanddips')
            OVER(PARTITION BY deviceId LIMIT DURATION(minute, 15)) AS AnomalyScores
    FROM [telemetry-input] TIMESTAMP BY timestamp
)
SELECT 
    deviceId,
    timestamp,
    temperature,
    humidity,
    pressure,
    CAST(GetRecordPropertyValue(AnomalyScores, 'Score') AS FLOAT) AS anomalyScore,
    CAST(GetRecordPropertyValue(AnomalyScores, 'IsAnomaly') AS BIGINT) AS isAnomaly,
    -- Visualization-friendly anomaly indicator
    CASE 
        WHEN CAST(GetRecordPropertyValue(AnomalyScores, 'IsAnomaly') AS BIGINT) = 1 
        THEN temperature 
        ELSE NULL 
    END AS anomalyTemperature,
    -- Alert level for conditional formatting
    CASE 
        WHEN CAST(GetRecordPropertyValue(AnomalyScores, 'Score') AS FLOAT) > 0.9 THEN 'Critical'
        WHEN CAST(GetRecordPropertyValue(AnomalyScores, 'Score') AS FLOAT) > 0.7 THEN 'High'
        WHEN CAST(GetRecordPropertyValue(AnomalyScores, 'Score') AS FLOAT) > 0.5 THEN 'Medium'
        ELSE 'Normal'
    END AS alertLevel
INTO [powerbi-dashboard]
FROM AnomalyData
```

### Step 6: Configure Real-time Alerts in Power BI

1. **Create Data Alert**:
   - Click on a KPI tile (e.g., Critical Alerts)
   - Click **"..."** → **"Manage alerts"**
   - Click **"+ Add alert rule"**

2. **Configure Alert Rule**:
   ```
   Condition: criticalAlerts is above 0
   Frequency: At most once per hour
   Notification: Email
   Recipients: [Your email]
   ```

3. **Set Up Multiple Alert Levels**:
   - **Critical**: Any device with temperature > 40°C
   - **Warning**: Average temperature > 30°C
   - **Info**: More than 5 devices offline

### Step 7: Dashboard Optimization

#### Performance Best Practices:

1. **Limit Data Retention**:
   ```sql
   -- Only keep last 24 hours of detailed data
   SELECT *
   INTO [powerbi-dashboard]
   FROM [telemetry-input] TIMESTAMP BY timestamp
   WHERE DATEDIFF(hour, timestamp, System.Timestamp()) <= 24
   ```

2. **Use Aggregated Data for Historical Views**:
   ```sql
   -- Hourly aggregates for longer-term trending
   SELECT 
       System.Timestamp() AS hourEnd,
       deviceId,
       AVG(temperature) AS avgTemperature,
       MIN(temperature) AS minTemperature,
       MAX(temperature) AS maxTemperature,
       AVG(humidity) AS avgHumidity,
       COUNT(*) AS eventCount
   INTO [powerbi-historical]
   FROM [telemetry-input] TIMESTAMP BY timestamp
   GROUP BY deviceId, TumblingWindow(hour, 1)
   ```

3. **Implement Data Sampling for High-Volume Streams**:
   ```sql
   -- Sample 1 in 10 events for visualization
   SELECT *
   INTO [powerbi-dashboard]
   FROM [telemetry-input] TIMESTAMP BY timestamp
   WHERE ABS(CHECKSUM(deviceId)) % 10 = 0
   ```

## 🔧 Testing and Validation

### Step 8: Test Real-time Dashboard

1. **Verify Data Flow**:
   - Start your Stream Analytics job
   - Wait 2-3 minutes for data to appear in Power BI
   - Check dataset refresh status in Power BI

2. **Test Visualizations**:
   - Verify tiles are updating automatically
   - Check that filters and slicers work correctly
   - Confirm geographic visualizations show correct locations

3. **Test Alerts**:
   - Generate test data that triggers alert conditions
   - Verify email notifications are received
   - Check alert frequency limits are working

## 📊 Advanced Visualization Techniques

### Custom Visualizations:

1. **Custom Streaming Visual**:
   - Use Power BI custom visuals marketplace
   - Install "Real-time Line Chart" or "Streaming Data" visuals
   - Configure for high-frequency updates

2. **Conditional Formatting**:
   ```
   Temperature Color Rules:
   - Green: 15-25°C
   - Yellow: 25-30°C or 10-15°C  
   - Orange: 30-35°C or 5-10°C
   - Red: >35°C or <5°C
   ```

3. **Dynamic Titles**:
   - Use DAX measures for dynamic tile titles
   - Include current values and timestamps
   - Show alert status in titles

## 🚨 Common Issues and Troubleshooting

### Issue 1: Dashboard Not Updating
**Symptoms**: Tiles show old data or "No data available"
**Solutions**:
- Check Stream Analytics job status and errors
- Verify Power BI output configuration
- Confirm Power BI dataset permissions
- Check for streaming dataset row limits (200,000 rows max)

### Issue 2: Poor Performance
**Symptoms**: Slow dashboard loading, browser freezing
**Solutions**:
- Reduce data retention period
- Implement data sampling
- Use aggregated queries instead of raw data
- Limit number of visuals on single dashboard

### Issue 3: Missing Geographic Data
**Symptoms**: Map visualizations empty or incomplete
**Solutions**:
- Verify latitude/longitude data is not null
- Check coordinate format (decimal degrees)
- Ensure location data is included in output query
- Validate geographic coordinate ranges

## 💡 Best Practices

1. **Dashboard Design**:
   - Limit to 10-15 tiles per dashboard
   - Use consistent color schemes
   - Group related metrics together
   - Include timestamp of last update

2. **Data Management**:
   - Implement automatic data cleanup
   - Use different aggregation levels for different time ranges
   - Monitor streaming dataset limits
   - Plan for data archival

3. **Performance Optimization**:
   - Cache frequently accessed data
   - Use incremental refresh where possible
   - Optimize queries for Power BI consumption
   - Monitor resource usage

4. **Alert Management**:
   - Set appropriate alert thresholds
   - Implement alert escalation
   - Use different notification channels for different severities
   - Include context in alert messages

## 🎯 Success Criteria

✅ Real-time dashboard showing live telemetry data  
✅ KPI tiles updating automatically with current values  
✅ Geographic visualization showing device locations  
✅ Anomaly detection integrated with visual alerts  
✅ Email alerts working for critical conditions  
✅ Dashboard loads within 3-5 seconds  
✅ Historical trends visible alongside real-time data  

## 📈 Cost Considerations

- **Power BI Licensing**: Pro ($10/user/month) or Premium ($20/user/month)
- **Stream Analytics**: Additional output adds minimal cost (~$5-10/month)
- **Data Storage**: Streaming datasets included in Power BI license
- **Alert Notifications**: Included in Power BI Pro/Premium
- **Estimated Total**: $10-30/month depending on user count

## 🔗 Next Steps

Continue to [Lab 9: Fabric RTI Overview](./lab-09-fabric-rti.md) to learn about Microsoft Fabric Real-Time Intelligence and advanced analytics capabilities.
