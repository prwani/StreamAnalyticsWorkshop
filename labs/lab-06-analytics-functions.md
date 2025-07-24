# Lab 6: Analytics Functions - Anomaly Detection

## 🎯 Lab Objectives

In this lab, you will:
- Understand Azure Stream Analytics built-in analytics functions
- Implement anomaly detection using machine learning algorithms
- Use ANOMALYDETECTION_SPIKEANDDIP for spike detection
- Use ANOMALYDETECTION_CHANGEPOINT for trend analysis
- Configure confidence levels and sensitivity parameters
- Handle anomaly alerts and notifications
- Monitor and tune anomaly detection performance

## 📋 Prerequisites

- Completed [Lab 5: Windowing Functions](./lab-05-windowing-functions.md)
- Understanding of time windows and aggregations
- Running Stream Analytics job with telemetry data
- Event Hub and output destinations configured

## 🤖 Understanding Anomaly Detection

### What is Anomaly Detection?
Anomaly detection identifies unusual patterns that do not conform to expected behavior. In IoT and streaming scenarios, this helps:
- Detect equipment failures before they occur
- Identify security threats or unusual access patterns
- Monitor system performance and resource utilization
- Trigger automated responses to unusual conditions

### Stream Analytics Anomaly Detection Functions:
1. **ANOMALYDETECTION_SPIKEANDDIP**: Detects temporary spikes and dips
2. **ANOMALYDETECTION_CHANGEPOINT**: Detects persistent changes in trends

## 📝 Step-by-Step Instructions

### Step 1: Spike and Dip Detection

Spike and dip detection identifies temporary anomalies that deviate significantly from the normal pattern.

#### Query 1: Basic Spike Detection for Temperature
```sql
-- Detect temperature spikes and dips with 95% confidence
WITH AnomalyDetectionStep AS
(
    SELECT
        deviceId,
        timestamp,
        temperature,
        ANOMALYDETECTION_SPIKEANDDIP(temperature, 95, 120, 'spikesanddips')
            OVER(PARTITION BY deviceId LIMIT DURATION(minute, 10)) AS SpikeAndDipScores
    FROM [telemetry-input] TIMESTAMP BY timestamp
)
SELECT
    deviceId,
    timestamp,
    temperature,
    CAST(GetRecordPropertyValue(SpikeAndDipScores, 'Score') AS FLOAT) AS AnomalyScore,
    CAST(GetRecordPropertyValue(SpikeAndDipScores, 'IsAnomaly') AS BIGINT) AS IsAnomaly
INTO [blob-output]
FROM AnomalyDetectionStep
WHERE CAST(GetRecordPropertyValue(SpikeAndDipScores, 'IsAnomaly') AS BIGINT) = 1
```

#### Query 2: Multi-Metric Spike Detection
```sql
-- Monitor multiple metrics for anomalies
WITH MultiMetricAnomalies AS
(
    SELECT
        deviceId,
        timestamp,
        temperature,
        humidity,
        pressure,
        -- Temperature anomalies
        ANOMALYDETECTION_SPIKEANDDIP(temperature, 90, 120, 'spikesanddips')
            OVER(PARTITION BY deviceId LIMIT DURATION(minute, 15)) AS TempAnomalies,
        -- Humidity anomalies  
        ANOMALYDETECTION_SPIKEANDDIP(humidity, 90, 120, 'spikesanddips')
            OVER(PARTITION BY deviceId LIMIT DURATION(minute, 15)) AS HumidityAnomalies,
        -- Pressure anomalies
        ANOMALYDETECTION_SPIKEANDDIP(pressure, 90, 120, 'spikesanddips')
            OVER(PARTITION BY deviceId LIMIT DURATION(minute, 15)) AS PressureAnomalies
    FROM [telemetry-input] TIMESTAMP BY timestamp
)
SELECT
    deviceId,
    timestamp,
    temperature,
    humidity,
    pressure,
    -- Temperature anomaly details
    CAST(GetRecordPropertyValue(TempAnomalies, 'Score') AS FLOAT) AS TempAnomalyScore,
    CAST(GetRecordPropertyValue(TempAnomalies, 'IsAnomaly') AS BIGINT) AS IsTempAnomaly,
    -- Humidity anomaly details
    CAST(GetRecordPropertyValue(HumidityAnomalies, 'Score') AS FLOAT) AS HumidityAnomalyScore,
    CAST(GetRecordPropertyValue(HumidityAnomalies, 'IsAnomaly') AS BIGINT) AS IsHumidityAnomaly,
    -- Pressure anomaly details
    CAST(GetRecordPropertyValue(PressureAnomalies, 'Score') AS FLOAT) AS PressureAnomalyScore,
    CAST(GetRecordPropertyValue(PressureAnomalies, 'IsAnomaly') AS BIGINT) AS IsPressureAnomaly,
    -- Combined anomaly flag
    CASE WHEN 
        CAST(GetRecordPropertyValue(TempAnomalies, 'IsAnomaly') AS BIGINT) = 1 OR
        CAST(GetRecordPropertyValue(HumidityAnomalies, 'IsAnomaly') AS BIGINT) = 1 OR
        CAST(GetRecordPropertyValue(PressureAnomalies, 'IsAnomaly') AS BIGINT) = 1
    THEN 1 ELSE 0 END AS IsAnyAnomaly
INTO [blob-output]
FROM MultiMetricAnomalies
WHERE 
    CAST(GetRecordPropertyValue(TempAnomalies, 'IsAnomaly') AS BIGINT) = 1 OR
    CAST(GetRecordPropertyValue(HumidityAnomalies, 'IsAnomaly') AS BIGINT) = 1 OR
    CAST(GetRecordPropertyValue(PressureAnomalies, 'IsAnomaly') AS BIGINT) = 1
```

### Step 2: Change Point Detection

Change point detection identifies when the statistical properties of the data stream change persistently.

#### Query 3: Temperature Trend Change Detection
```sql
-- Detect persistent changes in temperature trends
WITH ChangePointDetection AS
(
    SELECT
        deviceId,
        timestamp,
        temperature,
        ANOMALYDETECTION_CHANGEPOINT(temperature, 80, 120)
            OVER(PARTITION BY deviceId LIMIT DURATION(hour, 2)) AS ChangePointScores
    FROM [telemetry-input] TIMESTAMP BY timestamp
)
SELECT
    deviceId,
    timestamp,
    temperature,
    CAST(GetRecordPropertyValue(ChangePointScores, 'Score') AS FLOAT) AS ChangePointScore,
    CAST(GetRecordPropertyValue(ChangePointScores, 'IsChangePoint') AS BIGINT) AS IsChangePoint
INTO [blob-output]
FROM ChangePointDetection
WHERE CAST(GetRecordPropertyValue(ChangePointScores, 'IsChangePoint') AS BIGINT) = 1
```

#### Query 4: Advanced Change Point Analysis with Context
```sql
-- Change point detection with additional context and alerting
WITH ChangePointWithContext AS
(
    SELECT
        deviceId,
        timestamp,
        temperature,
        humidity,
        pressure,
        -- Calculate recent averages for context
        AVG(temperature) OVER(PARTITION BY deviceId ORDER BY timestamp 
            ROWS BETWEEN 10 PRECEDING AND CURRENT ROW) AS RecentAvgTemp,
        AVG(temperature) OVER(PARTITION BY deviceId ORDER BY timestamp 
            ROWS BETWEEN 50 PRECEDING AND 10 PRECEDING) AS HistoricalAvgTemp,
        -- Change point detection
        ANOMALYDETECTION_CHANGEPOINT(temperature, 85, 120)
            OVER(PARTITION BY deviceId LIMIT DURATION(hour, 3)) AS ChangePointScores
    FROM [telemetry-input] TIMESTAMP BY timestamp
),
ChangePointResults AS
(
    SELECT
        deviceId,
        timestamp,
        temperature,
        humidity,
        pressure,
        RecentAvgTemp,
        HistoricalAvgTemp,
        RecentAvgTemp - HistoricalAvgTemp AS TempDrift,
        CAST(GetRecordPropertyValue(ChangePointScores, 'Score') AS FLOAT) AS ChangePointScore,
        CAST(GetRecordPropertyValue(ChangePointScores, 'IsChangePoint') AS BIGINT) AS IsChangePoint
    FROM ChangePointWithContext
)
SELECT
    deviceId,
    timestamp,
    temperature,
    humidity,
    pressure,
    RecentAvgTemp,
    HistoricalAvgTemp,
    TempDrift,
    ChangePointScore,
    IsChangePoint,
    -- Alert severity based on drift magnitude
    CASE 
        WHEN ABS(TempDrift) > 10 THEN 'CRITICAL'
        WHEN ABS(TempDrift) > 5 THEN 'HIGH'
        WHEN ABS(TempDrift) > 2 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS AlertSeverity,
    -- Alert message
    CASE 
        WHEN TempDrift > 0 THEN 'Temperature trending upward by ' + CAST(TempDrift AS VARCHAR) + '°C'
        ELSE 'Temperature trending downward by ' + CAST(ABS(TempDrift) AS VARCHAR) + '°C'
    END AS AlertMessage
INTO [blob-output]
FROM ChangePointResults
WHERE IsChangePoint = 1
```

### Step 3: Combined Anomaly Detection System

#### Query 5: Comprehensive Anomaly Detection Dashboard
```sql
-- Combined spike detection and change point detection with alerting
WITH AnomalyAnalysis AS
(
    SELECT
        deviceId,
        timestamp,
        temperature,
        humidity,
        pressure,
        -- Spike and dip detection
        ANOMALYDETECTION_SPIKEANDDIP(temperature, 90, 120, 'spikesanddips')
            OVER(PARTITION BY deviceId LIMIT DURATION(minute, 20)) AS SpikeScores,
        -- Change point detection
        ANOMALYDETECTION_CHANGEPOINT(temperature, 80, 120)
            OVER(PARTITION BY deviceId LIMIT DURATION(hour, 2)) AS ChangeScores,
        -- Calculate moving statistics for context
        AVG(temperature) OVER(PARTITION BY deviceId ORDER BY timestamp 
            ROWS BETWEEN 20 PRECEDING AND CURRENT ROW) AS MovingAvg,
        STDEV(temperature) OVER(PARTITION BY deviceId ORDER BY timestamp 
            ROWS BETWEEN 20 PRECEDING AND CURRENT ROW) AS MovingStdDev
    FROM [telemetry-input] TIMESTAMP BY timestamp
),
AnomalyClassification AS
(
    SELECT
        deviceId,
        timestamp,
        temperature,
        humidity,
        pressure,
        MovingAvg,
        MovingStdDev,
        -- Spike detection results
        CAST(GetRecordPropertyValue(SpikeScores, 'Score') AS FLOAT) AS SpikeScore,
        CAST(GetRecordPropertyValue(SpikeScores, 'IsAnomaly') AS BIGINT) AS IsSpike,
        -- Change point results
        CAST(GetRecordPropertyValue(ChangeScores, 'Score') AS FLOAT) AS ChangeScore,
        CAST(GetRecordPropertyValue(ChangeScores, 'IsChangePoint') AS BIGINT) AS IsChangePoint,
        -- Manual threshold detection for comparison
        CASE WHEN ABS(temperature - MovingAvg) > (3 * MovingStdDev) THEN 1 ELSE 0 END AS IsStatisticalOutlier
    FROM AnomalyAnalysis
)
SELECT
    deviceId,
    timestamp,
    temperature,
    humidity,
    pressure,
    MovingAvg,
    MovingStdDev,
    SpikeScore,
    IsSpike,
    ChangeScore,
    IsChangePoint,
    IsStatisticalOutlier,
    -- Anomaly type classification
    CASE 
        WHEN IsSpike = 1 AND IsChangePoint = 1 THEN 'SPIKE_AND_TREND_CHANGE'
        WHEN IsSpike = 1 THEN 'TEMPORARY_SPIKE'
        WHEN IsChangePoint = 1 THEN 'TREND_CHANGE'
        WHEN IsStatisticalOutlier = 1 THEN 'STATISTICAL_OUTLIER'
        ELSE 'NORMAL'
    END AS AnomalyType,
    -- Priority scoring
    CASE 
        WHEN IsSpike = 1 AND IsChangePoint = 1 THEN 10
        WHEN IsChangePoint = 1 THEN 8
        WHEN IsSpike = 1 THEN 6
        WHEN IsStatisticalOutlier = 1 THEN 4
        ELSE 0
    END AS PriorityScore,
    -- Alert recommendation
    CASE 
        WHEN IsSpike = 1 AND IsChangePoint = 1 THEN 'IMMEDIATE_ATTENTION_REQUIRED'
        WHEN IsChangePoint = 1 THEN 'INVESTIGATE_TREND_CHANGE'
        WHEN IsSpike = 1 THEN 'MONITOR_FOR_RECURRENCE'
        WHEN IsStatisticalOutlier = 1 THEN 'LOG_FOR_REVIEW'
        ELSE 'NO_ACTION_NEEDED'
    END AS RecommendedAction
INTO [blob-output]
FROM AnomalyClassification
WHERE IsSpike = 1 OR IsChangePoint = 1 OR IsStatisticalOutlier = 1
```

### Step 4: Real-time Alerting Integration

#### Query 6: Anomaly Alerts to Event Hub
```sql
-- Send high-priority anomalies to Event Hub for real-time alerting
WITH CriticalAnomalies AS
(
    SELECT
        deviceId,
        timestamp,
        temperature,
        ANOMALYDETECTION_SPIKEANDDIP(temperature, 95, 120, 'spikesanddips')
            OVER(PARTITION BY deviceId LIMIT DURATION(minute, 10)) AS SpikeScores
    FROM [telemetry-input] TIMESTAMP BY timestamp
),
AlertPayload AS
(
    SELECT
        deviceId,
        timestamp,
        temperature,
        CAST(GetRecordPropertyValue(SpikeScores, 'Score') AS FLOAT) AS AnomalyScore,
        CAST(GetRecordPropertyValue(SpikeScores, 'IsAnomaly') AS BIGINT) AS IsAnomaly,
        'TEMPERATURE_ANOMALY' AS AlertType,
        CASE 
            WHEN CAST(GetRecordPropertyValue(SpikeScores, 'Score') AS FLOAT) > 0.9 THEN 'CRITICAL'
            WHEN CAST(GetRecordPropertyValue(SpikeScores, 'Score') AS FLOAT) > 0.7 THEN 'HIGH'
            ELSE 'MEDIUM'
        END AS Severity
    FROM CriticalAnomalies
    WHERE CAST(GetRecordPropertyValue(SpikeScores, 'IsAnomaly') AS BIGINT) = 1
)
SELECT
    deviceId,
    timestamp,
    temperature,
    AnomalyScore,
    AlertType,
    Severity,
    'Device ' + deviceId + ' temperature anomaly detected: ' + CAST(temperature AS VARCHAR) + '°C (Score: ' + CAST(AnomalyScore AS VARCHAR) + ')' AS AlertMessage,
    System.Timestamp() AS ProcessedTime
INTO [alert-eventhub]
FROM AlertPayload
WHERE Severity IN ('CRITICAL', 'HIGH')
```

## 🔧 Testing and Validation

### Step 5: Test Anomaly Detection

1. **Generate Test Data with Anomalies**:
   ```python
   # Add this to your data generator
   import random
   import time
   
   def generate_anomalous_data():
       # Normal temperature: 20-25°C
       # Inject spike: 40°C
       # Inject dip: 5°C
       
       if random.random() < 0.05:  # 5% chance of anomaly
           if random.random() < 0.5:
               return 40 + random.uniform(-2, 2)  # Spike
           else:
               return 5 + random.uniform(-2, 2)   # Dip
       else:
           return 22.5 + random.uniform(-2.5, 2.5)  # Normal
   ```

2. **Monitor Anomaly Detection Performance**:
   - Check Stream Analytics metrics for processing latency
   - Verify anomaly detection sensitivity
   - Monitor false positive rates

### Step 6: Parameter Tuning

#### Confidence Level Guidelines:
- **95%**: Very sensitive, may have false positives
- **90%**: Balanced sensitivity and specificity
- **80%**: Less sensitive, fewer false positives
- **70%**: Only detects major anomalies

#### History Length Guidelines:
- **Spike Detection**: 60-300 events (depends on data frequency)
- **Change Point**: 120-500 events (needs more history for trends)

## 📊 Monitoring and Performance

### Key Metrics to Monitor:
- **Anomaly Detection Rate**: Percentage of events flagged as anomalies
- **Processing Latency**: Time from event ingestion to anomaly detection
- **False Positive Rate**: Manual validation of flagged anomalies
- **Alert Response Time**: Time from detection to action

### Performance Optimization:
- Use appropriate window sizes for your data frequency
- Partition by device ID for parallel processing
- Consider sampling for high-volume streams
- Implement alert throttling to prevent spam

## 🚨 Common Issues and Troubleshooting

### Issue 1: Too Many False Positives
**Solution**: 
- Increase confidence level (e.g., 90% → 95%)
- Increase history length
- Add additional filters based on domain knowledge

### Issue 2: Missing Real Anomalies
**Solution**:
- Decrease confidence level (e.g., 90% → 80%)
- Check data quality and missing values
- Verify timestamp alignment

### Issue 3: High Processing Latency
**Solution**:
- Reduce window sizes
- Optimize partitioning strategy
- Consider scaling up Stream Analytics units

## 💡 Best Practices

1. **Start with Conservative Settings**: Begin with higher confidence levels and tune down
2. **Domain Knowledge Integration**: Combine ML anomalies with business rule checks
3. **Multi-layered Detection**: Use both spike detection and change point detection
4. **Alert Fatigue Prevention**: Implement alert throttling and severity levels
5. **Continuous Monitoring**: Regularly review and tune detection parameters
6. **Documentation**: Keep track of parameter changes and their effects

## 🎯 Success Criteria

✅ Successfully detect temperature spikes above normal range  
✅ Identify persistent trend changes in device behavior  
✅ Generate alerts with appropriate severity levels  
✅ Minimize false positives while catching real anomalies  
✅ Process anomaly detection within acceptable latency  
✅ Integration with downstream alerting systems working  

## 📈 Cost Considerations

- **Stream Analytics Units**: Anomaly detection increases CPU usage (~20-30%)
- **Storage Costs**: Anomaly logs typically 1-5% of total data volume
- **Alert Volume**: Budget for notification service costs
- **Estimated Additional Cost**: $10-30/month for typical IoT scenarios

## 🔗 Next Steps

Continue to [Lab 7: Real-time Power BI Visualization](./lab-07-powerbi-visualization.md) to learn how to visualize anomalies and create real-time dashboards.
