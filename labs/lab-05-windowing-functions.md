# Lab 5: Windowing Functions

## 🎯 Lab Objectives

In this lab, you will:
- Master the four types of windows: Tumbling, Hopping, Sliding, and Session
- Understand window sizing strategies and performance implications
- Handle late-arriving and out-of-order events
- Implement complex windowing patterns for real-time analytics
- Work with TIMESTAMP BY and event time semantics
- Optimize window performance

## 📋 Prerequisites

- Completed [Lab 4: Aggregate Functions](./lab-04-aggregate-functions.md)
- Understanding of aggregations and GROUP BY operations
- Running Stream Analytics job with continuous data flow

## 🕐 Understanding Time in Stream Analytics

### Time Concepts:
- **Event Time**: When the event actually occurred (from the data)
- **Ingestion Time**: When the event was received by Azure
- **Processing Time**: When the event is being processed

### Key Principles:
- **TIMESTAMP BY**: Defines which field represents the event time
- **Windows**: Define time boundaries for aggregations
- **Watermarks**: Handle late-arriving events

## 📝 Step-by-Step Instructions

### Step 1: Tumbling Windows

Tumbling windows are **non-overlapping**, **fixed-size** time intervals.

#### Query 1: Basic Tumbling Window
```sql
-- 5-minute tumbling windows
SELECT 
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS EventCount,
    AVG(temperature) AS AvgTemperature,
    MIN(temperature) AS MinTemperature,
    MAX(temperature) AS MaxTemperature,
    STDEV(temperature) AS TempStdDev
INTO [blob-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY TumblingWindow(minute, 5)
```

#### Query 2: Multiple Tumbling Window Sizes
```sql
-- Different window sizes for different analytics
-- 1-minute windows for immediate alerting
SELECT 
    'MINUTE' AS WindowType,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS EventCount,
    AVG(temperature) AS AvgTemperature,
    MAX(temperature) AS MaxTemperature
INTO [minute-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY TumblingWindow(minute, 1);

-- 15-minute windows for trend analysis
SELECT 
    'QUARTER_HOUR' AS WindowType,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS EventCount,
    AVG(temperature) AS AvgTemperature,
    STDEV(temperature) AS TempStdDev,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY temperature) AS TempMedian
INTO [quarter-hour-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY TumblingWindow(minute, 15);

-- 1-hour windows for historical analysis
SELECT 
    'HOUR' AS WindowType,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS EventCount,
    COUNT(DISTINCT deviceId) AS UniqueDevices,
    AVG(temperature) AS AvgTemperature,
    MIN(temperature) AS MinTemperature,
    MAX(temperature) AS MaxTemperature,
    STDEV(temperature) AS TempStdDev
INTO [hourly-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY TumblingWindow(hour, 1)
```

#### Query 3: Device-Specific Tumbling Windows
```sql
-- Per-device tumbling windows
SELECT 
    deviceId,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS ReadingCount,
    AVG(temperature) AS AvgTemperature,
    AVG(humidity) AS AvgHumidity,
    AVG(pressure) AS AvgPressure,
    -- Calculate temperature trend within window
    CASE 
        WHEN STDEV(temperature) > 5 THEN 'High Variation'
        WHEN STDEV(temperature) > 2 THEN 'Medium Variation'
        ELSE 'Low Variation'
    END AS TemperatureVariation
INTO [blob-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY deviceId, TumblingWindow(minute, 10)
HAVING COUNT(*) >= 3  -- Only output if we have at least 3 readings
```

### Step 2: Hopping Windows

Hopping windows **overlap** and have **fixed size** with a specified **hop interval**.

#### Query 4: Basic Hopping Window
```sql
-- 10-minute windows that advance every 5 minutes (50% overlap)
SELECT 
    System.Timestamp() AS WindowEnd,
    DATEADD(minute, -10, System.Timestamp()) AS WindowStart,
    COUNT(*) AS EventCount,
    AVG(temperature) AS AvgTemperature,
    STDEV(temperature) AS TempStdDev,
    'HOPPING_10MIN_5MIN' AS WindowType
INTO [blob-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY HoppingWindow(minute, 10, 5)
```

#### Query 5: Multiple Hopping Windows for Trend Analysis
```sql
-- Short-term trend (5-minute window, 1-minute hop)
SELECT 
    'SHORT_TERM' AS TrendType,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS EventCount,
    AVG(temperature) AS AvgTemperature,
    AVG(humidity) AS AvgHumidity,
    -- Calculate rate of change (simplified)
    AVG(temperature) - LAG(AVG(temperature)) OVER (ORDER BY System.Timestamp()) AS TempChangeRate
INTO [trend-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY HoppingWindow(minute, 5, 1);

-- Medium-term trend (15-minute window, 5-minute hop)
SELECT 
    'MEDIUM_TERM' AS TrendType,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS EventCount,
    AVG(temperature) AS AvgTemperature,
    STDEV(temperature) AS TempStdDev,
    MIN(temperature) AS MinTemperature,
    MAX(temperature) AS MaxTemperature
INTO [trend-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY HoppingWindow(minute, 15, 5)
```

#### Query 6: Overlapping Alert Windows
```sql
-- Overlapping windows to catch temperature spikes
SELECT 
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS ReadingCount,
    AVG(temperature) AS AvgTemperature,
    MAX(temperature) AS MaxTemperature,
    SUM(CASE WHEN temperature > 35 THEN 1 ELSE 0 END) AS HighTempCount,
    (SUM(CASE WHEN temperature > 35 THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS HighTempPercentage,
    CASE 
        WHEN MAX(temperature) > 40 THEN 'CRITICAL'
        WHEN AVG(temperature) > 32 THEN 'WARNING'
        WHEN (SUM(CASE WHEN temperature > 35 THEN 1 ELSE 0 END) * 100.0) / COUNT(*) > 50 THEN 'ALERT'
        ELSE 'NORMAL'
    END AS AlertLevel
INTO [alert-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY HoppingWindow(minute, 3, 1)  -- 3-minute window, 1-minute hop
HAVING 
    MAX(temperature) > 32 
    OR (SUM(CASE WHEN temperature > 35 THEN 1 ELSE 0 END) * 100.0) / COUNT(*) > 25
```

### Step 3: Sliding Windows

Sliding windows **continuously update** with each event and have a **fixed duration**.

#### Query 7: Basic Sliding Window
```sql
-- Sliding 10-minute window for continuous monitoring
SELECT 
    deviceId,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS EventCount,
    AVG(temperature) AS MovingAvgTemperature,
    MIN(temperature) AS MovingMinTemperature,
    MAX(temperature) AS MovingMaxTemperature,
    -- Moving range
    MAX(temperature) - MIN(temperature) AS MovingTempRange
INTO [blob-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY deviceId, SlidingWindow(minute, 10)
```

#### Query 8: Real-Time Anomaly Detection with Sliding Windows
```sql
-- Detect temperature anomalies using sliding windows
WITH MovingStats AS (
    SELECT 
        deviceId,
        temperature,
        timestamp,
        System.Timestamp() AS WindowEnd,
        AVG(temperature) OVER (PARTITION BY deviceId) AS MovingAvg,
        STDEV(temperature) OVER (PARTITION BY deviceId) AS MovingStdDev,
        COUNT(*) OVER (PARTITION BY deviceId) AS WindowSize
    FROM [telemetry-input] TIMESTAMP BY timestamp
    WINDOW SlidingWindow(minute, 15)
)
SELECT 
    deviceId,
    timestamp,
    temperature,
    WindowEnd,
    MovingAvg,
    MovingStdDev,
    WindowSize,
    -- Z-score calculation
    CASE 
        WHEN MovingStdDev > 0 THEN 
            (temperature - MovingAvg) / MovingStdDev
        ELSE 0
    END AS ZScore,
    -- Anomaly detection
    CASE 
        WHEN MovingStdDev > 0 AND ABS((temperature - MovingAvg) / MovingStdDev) > 2 THEN 'ANOMALY'
        WHEN MovingStdDev > 0 AND ABS((temperature - MovingAvg) / MovingStdDev) > 1.5 THEN 'UNUSUAL'
        ELSE 'NORMAL'
    END AS AnomalyStatus
INTO [anomaly-output]
FROM MovingStats
WHERE 
    WindowSize >= 5  -- Need at least 5 readings for reliable statistics
    AND MovingStdDev > 0
    AND ABS((temperature - MovingAvg) / MovingStdDev) > 1.5  -- Only output unusual or anomalous readings
```

### Step 4: Session Windows

Session windows group events that occur within a specified **timeout period** of each other.

#### Query 9: Basic Session Window
```sql
-- Group device events into sessions (30-minute timeout)
SELECT 
    deviceId,
    System.Timestamp() AS SessionEnd,
    COUNT(*) AS EventCount,
    MIN(timestamp) AS SessionStart,
    MAX(timestamp) AS LastEvent,
    DATEDIFF(minute, MIN(timestamp), MAX(timestamp)) AS SessionDurationMinutes,
    AVG(temperature) AS AvgTemperature,
    MIN(temperature) AS MinTemperature,
    MAX(temperature) AS MaxTemperature
INTO [blob-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY deviceId, SessionWindow(minute, 30)
HAVING COUNT(*) >= 2  -- Only sessions with multiple events
```

#### Query 10: Dynamic Session Windows Based on Activity
```sql
-- Variable session timeouts based on device type or activity
SELECT 
    deviceId,
    System.Timestamp() AS SessionEnd,
    COUNT(*) AS EventCount,
    MIN(timestamp) AS SessionStart,
    MAX(timestamp) AS LastEvent,
    DATEDIFF(second, MIN(timestamp), MAX(timestamp)) AS SessionDurationSeconds,
    AVG(temperature) AS SessionAvgTemperature,
    STDEV(temperature) AS SessionTempStdDev,
    -- Session characteristics
    CASE 
        WHEN COUNT(*) > 50 THEN 'High Activity'
        WHEN COUNT(*) > 20 THEN 'Medium Activity'
        ELSE 'Low Activity'
    END AS ActivityLevel,
    CASE 
        WHEN STDEV(temperature) > 10 THEN 'High Variability'
        WHEN STDEV(temperature) > 5 THEN 'Medium Variability'
        ELSE 'Low Variability'
    END AS VariabilityLevel
INTO [session-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY 
    deviceId, 
    SessionWindow(minute, 
        CASE 
            WHEN SUBSTRING(deviceId, 8, 1) = '0' THEN 60  -- Type 0 devices: 60-minute timeout
            WHEN SUBSTRING(deviceId, 8, 1) = '1' THEN 30  -- Type 1 devices: 30-minute timeout
            ELSE 15  -- Other devices: 15-minute timeout
        END
    )
```

### Step 5: Advanced Windowing Patterns

#### Query 11: Multi-Level Windowing
```sql
-- Combine different window types for comprehensive analysis
-- Level 1: Real-time sliding window for immediate detection
SELECT 
    'REALTIME' AS AnalysisLevel,
    deviceId,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS EventCount,
    AVG(temperature) AS AvgTemperature,
    CASE 
        WHEN AVG(temperature) > 35 THEN 'IMMEDIATE_ALERT'
        ELSE 'NORMAL'
    END AS Status
INTO [realtime-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY deviceId, SlidingWindow(minute, 5);

-- Level 2: Tactical hopping window for trend analysis
SELECT 
    'TACTICAL' AS AnalysisLevel,
    deviceId,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS EventCount,
    AVG(temperature) AS AvgTemperature,
    STDEV(temperature) AS TempStdDev,
    -- Trend calculation (simplified)
    CASE 
        WHEN STDEV(temperature) > 5 THEN 'INCREASING_VARIANCE'
        ELSE 'STABLE'
    END AS TrendStatus
INTO [tactical-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY deviceId, HoppingWindow(minute, 15, 5);

-- Level 3: Strategic tumbling window for historical patterns
SELECT 
    'STRATEGIC' AS AnalysisLevel,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS EventCount,
    COUNT(DISTINCT deviceId) AS ActiveDevices,
    AVG(temperature) AS OverallAvgTemperature,
    STDEV(temperature) AS OverallTempStdDev,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY temperature) AS TempMedian,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY temperature) AS Temp95thPercentile
INTO [strategic-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY TumblingWindow(hour, 1)
```

#### Query 12: Conditional Windowing
```sql
-- Different windowing strategies based on data characteristics
SELECT 
    deviceId,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS EventCount,
    AVG(temperature) AS AvgTemperature,
    STDEV(temperature) AS TempStdDev,
    CASE 
        WHEN COUNT(*) < 5 THEN 'SPARSE_DATA'
        WHEN STDEV(temperature) > 10 THEN 'HIGH_VARIABILITY'
        WHEN AVG(temperature) > 35 THEN 'HIGH_TEMPERATURE'
        ELSE 'NORMAL'
    END AS WindowCharacteristics
INTO [blob-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY 
    deviceId,
    -- Adaptive window size based on device ID
    CASE 
        WHEN SUBSTRING(deviceId, 8, 1) IN ('0', '1') THEN TumblingWindow(minute, 5)
        WHEN SUBSTRING(deviceId, 8, 1) IN ('2', '3') THEN TumblingWindow(minute, 10)
        ELSE TumblingWindow(minute, 15)
    END
```

### Step 6: Handling Late Arrivals and Watermarks

#### Query 13: Out-of-Order Event Handling
```sql
-- Configure job to handle events that arrive up to 5 minutes late
-- (This is configured at the job level, not in the query)
SELECT 
    deviceId,
    timestamp AS EventTime,
    System.Timestamp() AS ProcessingTime,
    DATEDIFF(second, timestamp, System.Timestamp()) AS LatencySeconds,
    temperature,
    humidity,
    pressure,
    CASE 
        WHEN DATEDIFF(second, timestamp, System.Timestamp()) > 300 THEN 'LATE_ARRIVAL'
        WHEN DATEDIFF(second, timestamp, System.Timestamp()) > 60 THEN 'DELAYED'
        ELSE 'ON_TIME'
    END AS ArrivalStatus
INTO [blob-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
```

#### Query 14: Watermark-Aware Aggregation
```sql
-- Aggregation with watermark considerations
SELECT 
    System.Timestamp() AS WindowEnd,
    DATEADD(minute, -10, System.Timestamp()) AS WindowStart,
    COUNT(*) AS EventCount,
    AVG(temperature) AS AvgTemperature,
    MIN(timestamp) AS EarliestEventTime,
    MAX(timestamp) AS LatestEventTime,
    DATEDIFF(second, MIN(timestamp), MAX(timestamp)) AS EventTimeSpanSeconds,
    -- Quality indicators
    COUNT(CASE WHEN DATEDIFF(second, timestamp, System.Timestamp()) <= 60 THEN 1 END) AS OnTimeEvents,
    COUNT(CASE WHEN DATEDIFF(second, timestamp, System.Timestamp()) > 60 THEN 1 END) AS LateEvents,
    (COUNT(CASE WHEN DATEDIFF(second, timestamp, System.Timestamp()) <= 60 THEN 1 END) * 100.0) 
        / COUNT(*) AS OnTimePercentage
INTO [blob-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY TumblingWindow(minute, 10)
```

## 🎛️ Window Performance Optimization

### Performance Tips:

1. **Choose Appropriate Window Size**:
   - Smaller windows = More frequent outputs, higher resource usage
   - Larger windows = Less frequent outputs, better throughput

2. **Limit Window Overlap**:
   - Too much overlap in hopping windows increases computation

3. **Use Appropriate Grouping**:
   - Avoid high-cardinality GROUP BY clauses

4. **Consider Event Volume**:
   - High-volume streams may need larger windows

#### Query 15: Performance-Optimized Windowing
```sql
-- Optimized window query for high-volume streams
SELECT 
    -- Use fewer groups for better performance
    CASE 
        WHEN deviceId LIKE 'device-00%' THEN 'GroupA'
        WHEN deviceId LIKE 'device-01%' THEN 'GroupB'
        ELSE 'GroupC'
    END AS DeviceGroup,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS EventCount,
    AVG(temperature) AS AvgTemperature,
    -- Pre-aggregate before expensive calculations
    SUM(CASE WHEN temperature > 30 THEN 1 ELSE 0 END) AS HighTempCount
INTO [blob-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY 
    CASE 
        WHEN deviceId LIKE 'device-00%' THEN 'GroupA'
        WHEN deviceId LIKE 'device-01%' THEN 'GroupB'
        ELSE 'GroupC'
    END,
    TumblingWindow(minute, 5)
HAVING COUNT(*) >= 10  -- Filter small windows to reduce output
```

## 🧪 Practice Exercises

### Exercise 1: Multi-Timeframe Dashboard
Create queries for:
- 1-minute tumbling windows for real-time alerts
- 5-minute hopping windows (2-minute hop) for trend detection
- 30-minute sliding windows for continuous monitoring

### Exercise 2: Session Analysis
Develop queries that:
- Track device communication sessions
- Identify gaps in device communication
- Calculate session characteristics and patterns

### Exercise 3: Advanced Anomaly Detection
Build queries that:
- Use multiple window types for anomaly detection
- Implement progressive alerting based on window duration
- Handle late-arriving events gracefully

## 🐛 Common Windowing Issues

### Issue 1: Window Size Too Small
```sql
-- ❌ Problem: Too frequent outputs
GROUP BY TumblingWindow(second, 1)

-- ✅ Solution: Use appropriate window size
GROUP BY TumblingWindow(minute, 5)
```

### Issue 2: Excessive Window Overlap
```sql
-- ❌ Problem: 90% overlap causing performance issues
GROUP BY HoppingWindow(minute, 10, 1)

-- ✅ Solution: Reduce overlap
GROUP BY HoppingWindow(minute, 10, 5)
```

### Issue 3: Missing TIMESTAMP BY
```sql
-- ❌ Problem: No event time specified
FROM [telemetry-input]
GROUP BY TumblingWindow(minute, 5)

-- ✅ Solution: Always specify TIMESTAMP BY
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY TumblingWindow(minute, 5)
```

## 🎯 Lab Success Criteria

✅ Successfully implemented tumbling windows with various sizes  
✅ Created hopping windows with different overlap strategies  
✅ Used sliding windows for continuous monitoring  
✅ Implemented session windows for activity grouping  
✅ Combined multiple window types for comprehensive analysis  
✅ Handled late-arriving events appropriately  
✅ Optimized window performance for high-volume scenarios  

## 🚀 Next Steps

Fantastic! You've mastered windowing functions in Stream Analytics.

**Next Lab**: [Lab 6: Analytics Functions](./lab-06-analytics-functions.md)

In the next lab, you'll learn about:
- Anomaly detection functions
- Pattern recognition with MATCH_RECOGNIZE
- Geospatial analytics
- Machine learning integration

## 📖 Additional Resources

- [Windowing in Stream Analytics](https://docs.microsoft.com/azure/stream-analytics/stream-analytics-window-functions)
- [Time Handling and Event Ordering](https://docs.microsoft.com/azure/stream-analytics/stream-analytics-time-handling)
- [TIMESTAMP BY Clause](https://docs.microsoft.com/azure/stream-analytics/stream-analytics-stream-analytics-query-patterns#timestamp-by)
- [Watermarks and Late Arrival](https://docs.microsoft.com/azure/stream-analytics/stream-analytics-time-handling#watermarks)

---

**Estimated Completion Time**: 90-120 minutes  
**Difficulty Level**: Intermediate to Advanced  
**Cost Impact**: ~$3-5 for the duration of the lab
