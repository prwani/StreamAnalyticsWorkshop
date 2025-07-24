---
layout: default
title: "Lab 4: Aggregate Functions"
nav_order: 4
parent: Labs
---

# Lab 4: Aggregate Functions

## 🎯 Lab Objectives

In this lab, you will:
- Master basic aggregate functions (COUNT, SUM, AVG, MIN, MAX)
- Learn statistical aggregate functions (STDEV, VAR, PERCENTILE)
- Understand GROUP BY operations with streaming data
- Implement time-based aggregations
- Work with HAVING clauses for filtered aggregations
- Handle NULL values in aggregations

## 📋 Prerequisites

- Completed [Lab 3: Data Manipulation Functions](./lab-03-data-manipulation.md)
- Understanding of SAQL syntax and data types
- Running Stream Analytics job with continuous data

## 📊 Understanding Aggregations in Streaming

Unlike traditional SQL, Stream Analytics processes continuous data streams. Aggregations work over **windows** of time rather than complete datasets.

### Key Concepts:
- **Temporal Windows**: Define time boundaries for aggregations
- **Grouping**: Partition data by specific fields
- **Incremental Processing**: Results update as new data arrives

## 📝 Step-by-Step Instructions

### Step 1: Basic Aggregate Functions

#### Query 1: Simple Aggregations Over Time Windows
```sql
-- Basic aggregations over 5-minute tumbling windows
SELECT 
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS EventCount,
    AVG(temperature) AS AvgTemperature,
    MIN(temperature) AS MinTemperature,
    MAX(temperature) AS MaxTemperature,
    SUM(CASE WHEN temperature > 30 THEN 1 ELSE 0 END) AS HighTempCount,
    AVG(humidity) AS AvgHumidity,
    AVG(pressure) AS AvgPressure
INTO [blob-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY TumblingWindow(minute, 5)
```

#### Query 2: Aggregations by Device
```sql
-- Per-device aggregations over 10-minute windows
SELECT 
    deviceId,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS ReadingCount,
    AVG(temperature) AS AvgTemp,
    MIN(temperature) AS MinTemp,
    MAX(temperature) AS MaxTemp,
    MAX(temperature) - MIN(temperature) AS TempRange,
    STDEV(temperature) AS TempStandardDeviation,
    AVG(humidity) AS AvgHumidity,
    AVG(pressure) AS AvgPressure
INTO [blob-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY deviceId, TumblingWindow(minute, 10)
```

### Step 2: Statistical Aggregate Functions

#### Query 3: Advanced Statistical Measures
```sql
-- Comprehensive statistical analysis per device
SELECT 
    deviceId,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS SampleSize,
    -- Temperature statistics
    AVG(temperature) AS TempMean,
    STDEV(temperature) AS TempStdDev,
    VAR(temperature) AS TempVariance,
    PERCENTILE_CONT(0.5) OVER (ORDER BY temperature) AS TempMedian,
    PERCENTILE_CONT(0.25) OVER (ORDER BY temperature) AS TempQ1,
    PERCENTILE_CONT(0.75) OVER (ORDER BY temperature) AS TempQ3,
    PERCENTILE_CONT(0.95) OVER (ORDER BY temperature) AS Temp95thPercentile,
    -- Humidity statistics
    AVG(humidity) AS HumidityMean,
    STDEV(humidity) AS HumidityStdDev,
    PERCENTILE_CONT(0.5) OVER (ORDER BY humidity) AS HumidityMedian,
    -- Pressure statistics
    AVG(pressure) AS PressureMean,
    STDEV(pressure) AS PressureStdDev
INTO [blob-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY deviceId, TumblingWindow(minute, 15)
HAVING COUNT(*) >= 5  -- Only windows with at least 5 readings
```

#### Query 4: Correlation and Covariance
```sql
-- Calculate correlations between sensor readings
SELECT 
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS SampleSize,
    AVG(temperature) AS AvgTemp,
    AVG(humidity) AS AvgHumidity,
    -- Manual correlation calculation for temp vs humidity
    (
        AVG(temperature * humidity) - (AVG(temperature) * AVG(humidity))
    ) / (
        SQRT(VAR(temperature)) * SQRT(VAR(humidity))
    ) AS TempHumidityCorrelation,
    -- Covariance
    AVG(temperature * humidity) - (AVG(temperature) * AVG(humidity)) AS TempHumidityCovariance
INTO [blob-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY TumblingWindow(minute, 20)
HAVING COUNT(*) >= 10
```

### Step 3: Multi-Level Grouping

#### Query 5: Hierarchical Grouping
```sql
-- Group by device type and location (assuming device naming convention)
SELECT 
    SUBSTRING(deviceId, 1, 6) AS DeviceType,
    CASE 
        WHEN location.lat > 40 THEN 'North'
        ELSE 'South'
    END AS LocationRegion,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS ReadingCount,
    COUNT(DISTINCT deviceId) AS DeviceCount,
    AVG(temperature) AS AvgTemperature,
    STDEV(temperature) AS TempStdDev,
    MIN(temperature) AS MinTemp,
    MAX(temperature) AS MaxTemp,
    AVG(humidity) AS AvgHumidity,
    AVG(pressure) AS AvgPressure
INTO [blob-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY 
    SUBSTRING(deviceId, 1, 6),
    CASE 
        WHEN location.lat > 40 THEN 'North'
        ELSE 'South'
    END,
    TumblingWindow(minute, 15)
```

#### Query 6: Time-Based Grouping
```sql
-- Group by hour of day to identify patterns
SELECT 
    DATEPART(hour, timestamp) AS HourOfDay,
    DATEPART(weekday, timestamp) AS DayOfWeek,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS ReadingCount,
    AVG(temperature) AS AvgTemperature,
    STDEV(temperature) AS TempStdDev,
    AVG(humidity) AS AvgHumidity,
    AVG(pressure) AS AvgPressure,
    -- Calculate temperature trend
    (MAX(temperature) + MIN(temperature)) / 2 AS TempMidpoint
INTO [blob-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY 
    DATEPART(hour, timestamp),
    DATEPART(weekday, timestamp),
    TumblingWindow(hour, 1)
```

### Step 4: Conditional Aggregations

#### Query 7: Conditional Counting and Summing
```sql
-- Conditional aggregations for alerting
SELECT 
    deviceId,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS TotalReadings,
    -- Conditional counts
    SUM(CASE WHEN temperature > 35 THEN 1 ELSE 0 END) AS CriticalTempCount,
    SUM(CASE WHEN temperature > 30 THEN 1 ELSE 0 END) AS HighTempCount,
    SUM(CASE WHEN temperature < 10 THEN 1 ELSE 0 END) AS LowTempCount,
    SUM(CASE WHEN humidity > 80 THEN 1 ELSE 0 END) AS HighHumidityCount,
    SUM(CASE WHEN pressure < 1000 THEN 1 ELSE 0 END) AS LowPressureCount,
    -- Percentage calculations
    (SUM(CASE WHEN temperature > 30 THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS HighTempPercentage,
    (SUM(CASE WHEN humidity > 80 THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS HighHumidityPercentage,
    -- Alert level determination
    CASE 
        WHEN (SUM(CASE WHEN temperature > 35 THEN 1 ELSE 0 END) * 100.0) / COUNT(*) > 20 THEN 'CRITICAL'
        WHEN (SUM(CASE WHEN temperature > 30 THEN 1 ELSE 0 END) * 100.0) / COUNT(*) > 50 THEN 'WARNING'
        ELSE 'NORMAL'
    END AS AlertLevel
INTO [blob-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY deviceId, TumblingWindow(minute, 5)
```

#### Query 8: Value-Based Aggregations
```sql
-- Aggregate only specific value ranges
SELECT 
    System.Timestamp() AS WindowEnd,
    -- All readings
    COUNT(*) AS TotalReadings,
    AVG(temperature) AS OverallAvgTemp,
    -- Normal range only (15-35°C)
    COUNT(CASE WHEN temperature BETWEEN 15 AND 35 THEN 1 END) AS NormalRangeCount,
    AVG(CASE WHEN temperature BETWEEN 15 AND 35 THEN temperature END) AS NormalRangeAvgTemp,
    -- Extreme readings
    COUNT(CASE WHEN temperature < 0 OR temperature > 40 THEN 1 END) AS ExtremeReadings,
    AVG(CASE WHEN temperature < 0 OR temperature > 40 THEN temperature END) AS ExtremeAvgTemp,
    -- Quality readings (all sensors within normal range)
    SUM(
        CASE 
            WHEN temperature BETWEEN 15 AND 35 
                AND humidity BETWEEN 20 AND 80 
                AND pressure BETWEEN 1000 AND 1050 
            THEN 1 
            ELSE 0 
        END
    ) AS QualityReadings
INTO [blob-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY TumblingWindow(minute, 10)
```

### Step 5: Advanced Aggregation Patterns

#### Query 9: Running Aggregations with Multiple Windows
```sql
-- Multiple window sizes for different analytics
-- Short-term (5 minutes)
SELECT 
    'short_term' AS WindowType,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS ReadingCount,
    AVG(temperature) AS AvgTemperature,
    STDEV(temperature) AS TempStdDev
INTO [short-term-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY TumblingWindow(minute, 5);

-- Medium-term (30 minutes)
SELECT 
    'medium_term' AS WindowType,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS ReadingCount,
    AVG(temperature) AS AvgTemperature,
    STDEV(temperature) AS TempStdDev,
    PERCENTILE_CONT(0.5) OVER (ORDER BY temperature) AS TempMedian
INTO [medium-term-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY TumblingWindow(minute, 30);

-- Long-term (2 hours)
SELECT 
    'long_term' AS WindowType,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS ReadingCount,
    AVG(temperature) AS AvgTemperature,
    STDEV(temperature) AS TempStdDev,
    MIN(temperature) AS MinTemp,
    MAX(temperature) AS MaxTemp,
    PERCENTILE_CONT(0.1) OVER (ORDER BY temperature) AS Temp10thPercentile,
    PERCENTILE_CONT(0.9) OVER (ORDER BY temperature) AS Temp90thPercentile
INTO [long-term-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY TumblingWindow(hour, 2)
```

#### Query 10: Anomaly Detection with Aggregations
```sql
-- Detect anomalies using statistical aggregations
WITH StatsWindow AS (
    SELECT 
        System.Timestamp() AS WindowEnd,
        AVG(temperature) AS AvgTemp,
        STDEV(temperature) AS StdDevTemp,
        PERCENTILE_CONT(0.25) OVER (ORDER BY temperature) AS Q1Temp,
        PERCENTILE_CONT(0.75) OVER (ORDER BY temperature) AS Q3Temp,
        COUNT(*) AS ReadingCount
    FROM [telemetry-input] TIMESTAMP BY timestamp
    GROUP BY TumblingWindow(minute, 15)
)
SELECT 
    WindowEnd,
    ReadingCount,
    AvgTemp,
    StdDevTemp,
    Q1Temp,
    Q3Temp,
    -- Outlier bounds using IQR method
    Q1Temp - 1.5 * (Q3Temp - Q1Temp) AS LowerOutlierBound,
    Q3Temp + 1.5 * (Q3Temp - Q1Temp) AS UpperOutlierBound,
    -- Z-score bounds (2 standard deviations)
    AvgTemp - 2 * StdDevTemp AS LowerZScoreBound,
    AvgTemp + 2 * StdDevTemp AS UpperZScoreBound,
    -- Coefficient of variation (relative variability)
    CASE 
        WHEN AvgTemp != 0 THEN (StdDevTemp / ABS(AvgTemp)) * 100
        ELSE 0
    END AS CoefficientOfVariation
INTO [stats-output]
FROM StatsWindow
WHERE ReadingCount >= 10
```

### Step 6: Working with NULL Values

#### Query 11: NULL-Aware Aggregations
```sql
-- Handle NULL values in aggregations
SELECT 
    deviceId,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS TotalRecords,
    COUNT(temperature) AS ValidTempReadings,
    COUNT(humidity) AS ValidHumidityReadings,
    COUNT(pressure) AS ValidPressureReadings,
    -- NULL counts
    COUNT(*) - COUNT(temperature) AS MissingTempCount,
    COUNT(*) - COUNT(humidity) AS MissingHumidityCount,
    COUNT(*) - COUNT(pressure) AS MissingPressureCount,
    -- Data completeness percentages
    (COUNT(temperature) * 100.0) / COUNT(*) AS TempCompletenessPercent,
    (COUNT(humidity) * 100.0) / COUNT(*) AS HumidityCompletenessPercent,
    (COUNT(pressure) * 100.0) / COUNT(*) AS PressureCompletenessPercent,
    -- Aggregations (automatically ignore NULLs)
    AVG(temperature) AS AvgTemp,
    AVG(humidity) AS AvgHumidity,
    AVG(pressure) AS AvgPressure,
    -- Data quality score
    (
        (COUNT(temperature) * 100.0) / COUNT(*) +
        (COUNT(humidity) * 100.0) / COUNT(*) +
        (COUNT(pressure) * 100.0) / COUNT(*)
    ) / 3 AS OverallDataQuality
INTO [blob-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY deviceId, TumblingWindow(minute, 10)
```

## 🔍 HAVING Clause for Filtered Aggregations

### Step 7: Using HAVING for Quality Control

#### Query 12: Quality-Filtered Aggregations
```sql
-- Only process groups with sufficient data quality
SELECT 
    deviceId,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS ReadingCount,
    AVG(temperature) AS AvgTemperature,
    STDEV(temperature) AS TempStdDev,
    MIN(temperature) AS MinTemp,
    MAX(temperature) AS MaxTemp,
    AVG(humidity) AS AvgHumidity,
    AVG(pressure) AS AvgPressure,
    -- Data quality metrics
    (COUNT(temperature) * 100.0) / COUNT(*) AS TempCompletenessPercent
INTO [blob-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY deviceId, TumblingWindow(minute, 15)
HAVING 
    COUNT(*) >= 5  -- At least 5 readings
    AND (COUNT(temperature) * 100.0) / COUNT(*) >= 80  -- 80% temperature data completeness
    AND (COUNT(humidity) * 100.0) / COUNT(*) >= 70     -- 70% humidity data completeness
    AND STDEV(temperature) < 20  -- Reasonable temperature variation
```

#### Query 13: Alert-Filtered Aggregations
```sql
-- Only output windows that meet alert conditions
SELECT 
    deviceId,
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS ReadingCount,
    AVG(temperature) AS AvgTemperature,
    MAX(temperature) AS MaxTemperature,
    MIN(temperature) AS MinTemperature,
    SUM(CASE WHEN temperature > 35 THEN 1 ELSE 0 END) AS CriticalCount,
    (SUM(CASE WHEN temperature > 35 THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS CriticalPercentage,
    'HIGH_TEMPERATURE_ALERT' AS AlertType
INTO [alert-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY deviceId, TumblingWindow(minute, 5)
HAVING 
    AVG(temperature) > 32  -- Average temperature above threshold
    OR MAX(temperature) > 40  -- Any reading above critical threshold
    OR (SUM(CASE WHEN temperature > 35 THEN 1 ELSE 0 END) * 100.0) / COUNT(*) > 25  -- >25% critical readings
```

## 🧪 Practice Exercises

### Exercise 1: Environmental Monitoring Dashboard
Create queries that:
- Calculate hourly, daily, and weekly environmental statistics
- Identify peak usage hours and seasonal patterns
- Generate environmental quality indexes

### Exercise 2: Device Health Monitoring
Develop queries that:
- Monitor data transmission patterns per device
- Calculate device reliability scores
- Identify devices with unusual reading patterns

### Exercise 3: Multi-Sensor Correlation Analysis
Build queries that:
- Calculate correlations between different sensor types
- Identify environmental factor relationships
- Generate predictive indicators

## 🧩 Complex Aggregation Scenarios

### Scenario 1: Real-Time Air Quality Index
```sql
-- Calculate Air Quality Index based on multiple factors
SELECT 
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS SampleSize,
    AVG(temperature) AS AvgTemperature,
    AVG(humidity) AS AvgHumidity,
    AVG(pressure) AS AvgPressure,
    -- Simplified AQI calculation
    CASE 
        WHEN AVG(humidity) > 85 AND AVG(temperature) > 30 THEN 'Poor'
        WHEN AVG(humidity) > 70 AND AVG(temperature) > 25 THEN 'Moderate'
        WHEN AVG(humidity) BETWEEN 40 AND 60 AND AVG(temperature) BETWEEN 20 AND 25 THEN 'Good'
        ELSE 'Fair'
    END AS AirQualityCategory,
    -- Numeric AQI score (0-100) - Using CASE for bounds checking
    CASE 
        WHEN (50 - ABS(AVG(temperature) - 22.5) * 2 + 50 - ABS(AVG(humidity) - 50) + (AVG(pressure) - 1000) / 2) < 0 THEN 0
        WHEN (50 - ABS(AVG(temperature) - 22.5) * 2 + 50 - ABS(AVG(humidity) - 50) + (AVG(pressure) - 1000) / 2) > 100 THEN 100
        ELSE (50 - ABS(AVG(temperature) - 22.5) * 2 + 50 - ABS(AVG(humidity) - 50) + (AVG(pressure) - 1000) / 2)
    END AS AQIScore
INTO [aqi-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY TumblingWindow(minute, 15)
HAVING COUNT(*) >= 10
```

## 🐛 Common Aggregation Issues

### Issue 1: Empty Groups
```sql
-- ❌ Problem: Division by zero in aggregations
SELECT AVG(temperature) / COUNT(*) FROM [telemetry-input] GROUP BY TumblingWindow(minute, 5)

-- ✅ Solution: Use HAVING to ensure minimum group size
SELECT 
    AVG(temperature),
    COUNT(*) AS ReadingCount
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY TumblingWindow(minute, 5)
HAVING COUNT(*) > 0
```

### Issue 2: NULL Value Handling
```sql
-- ❌ Problem: NULLs affecting calculations
SELECT SUM(temperature) / COUNT(*) FROM [telemetry-input] GROUP BY TumblingWindow(minute, 5)

-- ✅ Solution: Use COUNT() of specific columns
SELECT 
    SUM(temperature) / COUNT(temperature) AS AvgTemp,
    AVG(temperature) AS AvgTempBuiltIn  -- Built-in AVG handles NULLs correctly
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY TumblingWindow(minute, 5)
```

## 🎯 Lab Success Criteria

✅ Successfully implemented basic aggregate functions (COUNT, SUM, AVG, MIN, MAX)  
✅ Applied statistical functions (STDEV, VAR, PERCENTILE)  
✅ Created multi-level grouping operations  
✅ Implemented conditional aggregations  
✅ Used HAVING clauses for filtered aggregations  
✅ Handled NULL values appropriately in aggregations  
✅ Built complex aggregation scenarios for real-world use cases  

## 🚀 Next Steps

Outstanding! You've mastered aggregate functions in Stream Analytics.

**Next Lab**: [Lab 5: Windowing Functions](./lab-05-windowing-functions.md)

In the next lab, you'll learn about:
- Tumbling, Hopping, Sliding, and Session windows
- Window sizing and overlap strategies
- Late arrival and out-of-order event handling
- Advanced windowing patterns

## 📖 Additional Resources

- [Aggregate Functions in Stream Analytics](https://docs.microsoft.com/azure/stream-analytics/stream-analytics-stream-analytics-query-patterns#aggregate-functions)
- [GROUP BY Clause](https://docs.microsoft.com/azure/stream-analytics/stream-analytics-stream-analytics-query-patterns#group-by)
- [Statistical Functions](https://docs.microsoft.com/azure/stream-analytics/stream-analytics-stream-analytics-query-patterns#statistical-functions)
- [HAVING Clause](https://docs.microsoft.com/azure/stream-analytics/stream-analytics-stream-analytics-query-patterns#having)

---

**Estimated Completion Time**: 90-120 minutes  
**Difficulty Level**: Intermediate to Advanced  
**Cost Impact**: ~$3-5 for the duration of the lab
