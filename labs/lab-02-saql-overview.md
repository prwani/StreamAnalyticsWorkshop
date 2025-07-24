# Lab 2: Stream Analytics Query Language (SAQL) Overview

## 🎯 Lab Objectives

In this lab, you will:
- Understand Stream Analytics Query Language (SAQL) syntax
- Learn about data types and operators
- Practice basic query patterns
- Explore temporal operations
- Work with JSON data structures
- Debug and optimize queries

## 📋 Prerequisites

- Completed [Lab 1: Stream Analytics Job 101](./lab-01-sa-job-101.md)
- Running Stream Analytics job with Event Hub input
- Sample telemetry data flowing through the pipeline

## 🔍 SAQL Fundamentals

Stream Analytics Query Language is based on SQL with extensions for temporal processing and streaming data patterns.

### Basic Query Structure

```sql
SELECT [columns]
INTO [output-alias]
FROM [input-alias]
[WHERE conditions]
[GROUP BY grouping-columns]
[HAVING group-conditions]
```

### Key Differences from Traditional SQL

1. **Temporal Nature**: Continuous data processing
2. **Windows**: Time-based grouping operations
3. **Event Time**: Built-in timestamp handling
4. **Streaming Operators**: Real-time specific functions

## 📝 Step-by-Step Instructions

### Step 1: Understand Your Data Schema

First, let's examine the telemetry data structure we'll be working with:

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
  "metadata": {
    "sensorType": "DHT22",
    "firmware": "v1.2.3"
  }
}
```

### Step 2: Basic Selection Queries

Navigate to your Stream Analytics job **Query** editor and try these examples:

#### Query 1: Select Specific Columns
```sql
-- Select only temperature and humidity data
SELECT 
    deviceId,
    timestamp,
    temperature,
    humidity,
    System.Timestamp() AS ProcessedTime
INTO [blob-output]
FROM [telemetry-input]
```

#### Query 2: Column Aliasing and Calculations
```sql
-- Rename columns and add calculated fields
SELECT 
    deviceId AS Device,
    timestamp AS EventTime,
    temperature AS TempCelsius,
    temperature * 9.0/5.0 + 32 AS TempFahrenheit,
    humidity AS HumidityPercent,
    CASE 
        WHEN temperature > 30 THEN 'Hot'
        WHEN temperature > 20 THEN 'Warm' 
        ELSE 'Cold'
    END AS TemperatureCategory
INTO [blob-output]
FROM [telemetry-input]
```

#### Query 3: Working with Nested JSON
```sql
-- Extract nested properties
SELECT 
    deviceId,
    timestamp,
    temperature,
    location.lat AS Latitude,
    location.lon AS Longitude,
    metadata.sensorType AS SensorType,
    metadata.firmware AS FirmwareVersion
INTO [blob-output]
FROM [telemetry-input]
```

### Step 3: Filtering with WHERE Clause

#### Query 4: Simple Filtering
```sql
-- Filter high temperature readings
SELECT 
    deviceId,
    timestamp,
    temperature,
    humidity,
    'HIGH_TEMP_ALERT' AS AlertType
INTO [blob-output]
FROM [telemetry-input]
WHERE temperature > 30
```

#### Query 5: Complex Filtering
```sql
-- Multiple conditions with logical operators
SELECT 
    deviceId,
    timestamp,
    temperature,
    humidity,
    pressure
INTO [blob-output]
FROM [telemetry-input]
WHERE 
    temperature > 25 
    AND humidity < 40 
    OR pressure > 1020
```

#### Query 6: Pattern Matching
```sql
-- Filter by device ID pattern
SELECT *
INTO [blob-output]
FROM [telemetry-input]
WHERE deviceId LIKE 'device-00%'
```

### Step 4: Data Type Conversions and Functions

#### Query 7: String Functions
```sql
-- String manipulation functions
SELECT 
    deviceId,
    UPPER(deviceId) AS DeviceIdUpper,
    LEN(deviceId) AS DeviceIdLength,
    SUBSTRING(deviceId, 8, 3) AS DeviceNumber,
    CONCAT(deviceId, '_processed') AS ProcessedDeviceId
INTO [blob-output]
FROM [telemetry-input]
```

#### Query 8: Mathematical Functions
```sql
-- Mathematical operations and functions
SELECT 
    deviceId,
    temperature,
    ROUND(temperature, 1) AS TempRounded,
    ABS(temperature - 25) AS TempDeviation,
    POWER(temperature, 2) AS TempSquared,
    SQRT(pressure) AS PressureSqrt
INTO [blob-output]
FROM [telemetry-input]
```

#### Query 9: DateTime Functions
```sql
-- Working with timestamps
SELECT 
    deviceId,
    timestamp,
    System.Timestamp() AS ProcessingTime,
    DATEPART(hour, timestamp) AS EventHour,
    CASE 
        WHEN DATEPART(day, timestamp) % 7 = 0 THEN 'Sunday'
        WHEN DATEPART(day, timestamp) % 7 = 1 THEN 'Monday'
        WHEN DATEPART(day, timestamp) % 7 = 2 THEN 'Tuesday'
        WHEN DATEPART(day, timestamp) % 7 = 3 THEN 'Wednesday'
        WHEN DATEPART(day, timestamp) % 7 = 4 THEN 'Thursday'
        WHEN DATEPART(day, timestamp) % 7 = 5 THEN 'Friday'
        WHEN DATEPART(day, timestamp) % 7 = 6 THEN 'Saturday'
        ELSE ''
    END AS DayOfWeekName,
    DATEDIFF(second, timestamp, System.Timestamp()) AS ProcessingDelaySeconds
INTO [blob-output]
FROM [telemetry-input]
```

### Step 5: Conditional Logic

#### Query 10: CASE Statements
```sql
-- Complex conditional logic
SELECT 
    deviceId,
    temperature,
    humidity,
    CASE 
        WHEN temperature > 35 THEN 'CRITICAL'
        WHEN temperature > 30 THEN 'WARNING'
        WHEN temperature > 25 THEN 'NORMAL'
        ELSE 'LOW'
    END AS TemperatureStatus,
    CASE 
        WHEN humidity > 80 THEN 'Very Humid'
        WHEN humidity > 60 THEN 'Humid'
        WHEN humidity > 40 THEN 'Moderate'
        ELSE 'Dry'
    END AS HumidityLevel
INTO [blob-output]
FROM [telemetry-input]
```

#### Query 11: NULL Handling
```sql
-- Handle missing or null values
SELECT 
    deviceId,
    COALESCE(temperature, 0) AS Temperature,
    COALESCE(humidity, 50) AS Humidity,
    COALESCE(pressure, 1013.25) AS Pressure,
    CASE 
        WHEN temperature IS NULL THEN 'Missing Temperature'
        ELSE 'Valid Reading'
    END AS DataQuality
INTO [blob-output]
FROM [telemetry-input]
```

### Step 6: Multiple Outputs

You can send different subsets of data to different outputs:

#### Query 12: Conditional Routing
```sql
-- Route high temperature alerts to different output
SELECT 
    deviceId,
    timestamp,
    temperature,
    'ALERT' AS MessageType
INTO [alert-output]
FROM [telemetry-input]
WHERE temperature > 35;

-- Route normal data to regular output
SELECT 
    deviceId,
    timestamp,
    temperature,
    humidity,
    pressure
INTO [blob-output]
FROM [telemetry-input]
WHERE temperature <= 35
```

Note: You'll need to create an additional output called `alert-output` for this to work.

### Step 7: Working with Arrays (if present in data)

If your data contains arrays, you can work with them:

#### Query 13: Array Operations
```sql
-- Assuming data has an array field like "sensors": ["temp", "humid", "pressure"]
SELECT 
    deviceId,
    GetArrayElement(sensors, 0) AS FirstSensor,
    GetArrayLength(sensors) AS SensorCount
INTO [blob-output]
FROM [telemetry-input]
WHERE GetArrayLength(sensors) > 0
```

### Step 8: Testing Queries

#### Using Query Test Features

1. **Test with Sample Data**:
   - In the Query editor, click **"Test query"**
   - Upload a sample JSON file or use live input
   - Review the output

2. **Sample Test Data** (save as `sample-data.json`):
   ```json
   [
     {
       "deviceId": "device-001",
       "timestamp": "2024-01-15T10:00:00.000Z",
       "temperature": 25.5,
       "humidity": 60.2,
       "pressure": 1013.25,
       "location": {"lat": 47.6062, "lon": -122.3321}
     },
     {
       "deviceId": "device-002", 
       "timestamp": "2024-01-15T10:01:00.000Z",
       "temperature": 32.1,
       "humidity": 45.8,
       "pressure": 1015.75,
       "location": {"lat": 40.7128, "lon": -74.0060}
     },
     {
       "deviceId": "device-003",
       "timestamp": "2024-01-15T10:02:00.000Z", 
       "temperature": 18.9,
       "humidity": 75.3,
       "pressure": 1009.5,
       "location": {"lat": 34.0522, "lon": -118.2437}
     }
   ]
   ```

## 🔍 Data Types in SAQL

### Supported Data Types

| Type | Examples | Notes |
|------|----------|--------|
| bigint | 1234567890 | 64-bit integer |
| float | 25.5, 3.14159 | Double precision |
| nvarchar(max) | "Hello World" | Unicode string |
| datetime | "2024-01-15T10:00:00Z" | ISO 8601 format |
| bit | true, false | Boolean values |
| record | {"lat": 47.6, "lon": -122.3} | Nested object |
| array | [1, 2, 3, "a", "b"] | Array of values |

### Type Conversion Functions

```sql
-- Convert between types
SELECT 
    deviceId,
    CAST(temperature AS bigint) AS TempInteger,
    CAST(deviceId AS nvarchar(max)) AS DeviceString,
    TRY_CAST(metadata.version AS float) AS Version
FROM [telemetry-input]
```

## 🚀 Advanced Query Patterns

### Pattern 1: Data Enrichment
```sql
-- Add computed fields and metadata
SELECT 
    deviceId,
    timestamp,
    temperature,
    humidity,
    pressure,
    -- Calculated fields
    temperature * 9.0/5.0 + 32 AS temperatureFahrenheit,
    (humidity * pressure) / 100.0 AS humidityPressureIndex,
    -- Metadata
    'telemetry' AS dataType,
    'v1.0' AS schemaVersion,
    System.Timestamp() AS processedTimestamp
INTO [blob-output]
FROM [telemetry-input]
```

### Pattern 2: Data Validation
```sql
-- Filter and validate data quality
SELECT 
    deviceId,
    timestamp,
    temperature,
    humidity,
    pressure,
    CASE 
        WHEN temperature IS NOT NULL AND temperature BETWEEN -50 AND 100 THEN 'Valid'
        ELSE 'Invalid'
    END AS temperatureValid,
    CASE 
        WHEN humidity IS NOT NULL AND humidity BETWEEN 0 AND 100 THEN 'Valid'
        ELSE 'Invalid'  
    END AS humidityValid
INTO [blob-output]
FROM [telemetry-input]
WHERE 
    temperature IS NOT NULL 
    AND humidity IS NOT NULL 
    AND pressure IS NOT NULL
    AND temperature BETWEEN -50 AND 100
    AND humidity BETWEEN 0 AND 100
    AND pressure BETWEEN 800 AND 1200
```

### Pattern 3: Event Classification
```sql
-- Classify events into categories
SELECT 
    deviceId,
    timestamp,
    temperature,
    humidity,
    pressure,
    CASE 
        WHEN temperature > 35 OR humidity > 90 THEN 'Critical'
        WHEN temperature > 30 OR humidity > 80 THEN 'Warning'
        WHEN temperature < 0 OR humidity < 10 THEN 'Anomaly'
        ELSE 'Normal'
    END AS eventSeverity,
    CASE 
        WHEN temperature > 30 AND humidity > 70 THEN 'Hot_Humid'
        WHEN temperature > 30 AND humidity < 30 THEN 'Hot_Dry'
        WHEN temperature < 10 AND humidity > 80 THEN 'Cold_Humid'
        WHEN temperature < 10 AND humidity < 30 THEN 'Cold_Dry'
        ELSE 'Moderate'
    END AS climateCondition
INTO [blob-output]
FROM [telemetry-input]
```

## 🐛 Common Query Issues and Solutions

### Issue 1: Type Mismatch Errors
**Problem**: Comparing different data types
```sql
-- ❌ Wrong: Comparing string to number
WHERE deviceId > 100

-- ✅ Correct: Proper type handling
WHERE CAST(SUBSTRING(deviceId, 8, 10) AS bigint) > 100
```

### Issue 2: NULL Reference Errors
**Problem**: Accessing properties that might be null
```sql
-- ❌ Wrong: Direct access to potentially null nested property
SELECT location.lat FROM [telemetry-input]

-- ✅ Correct: Check for null first
SELECT 
    CASE 
        WHEN location IS NOT NULL THEN location.lat 
        ELSE NULL 
    END AS latitude
FROM [telemetry-input]
```

### Issue 3: JSON Parsing Issues
**Problem**: Malformed JSON or incorrect property access
```sql
-- ❌ Wrong: Incorrect property path
SELECT metadata.sensor.type FROM [telemetry-input]

-- ✅ Correct: Use proper JSON functions
SELECT GetRecordPropertyValue(metadata, 'sensorType') AS sensorType
FROM [telemetry-input]
```

## 🧪 Practice Exercises

### Exercise 1: Temperature Converter
Create a query that:
- Converts temperature from Celsius to Fahrenheit and Kelvin
- Categorizes temperature as Freezing, Cold, Mild, Warm, or Hot
- Adds a comfort index based on temperature and humidity

### Exercise 2: Data Quality Monitor
Create a query that:
- Identifies records with missing critical fields
- Flags outlier values (temperature < -40 or > 60)
- Calculates data completeness percentage

### Exercise 3: Multi-Condition Filtering
Create a query that:
- Filters for specific device patterns
- Applies different temperature thresholds by location
- Routes different alert levels to separate outputs

## 📊 Query Performance Tips

1. **Filter Early**: Use WHERE clauses to reduce data volume
2. **Avoid Complex Calculations**: Minimize expensive operations in SELECT
3. **Use Appropriate Data Types**: Don't over-cast data types
4. **Limit OUTPUT**: Only select needed columns
5. **Test with Sample Data**: Validate logic before deploying

## 🔍 Verification Steps

1. **Test Each Query**:
   - Use the query test feature
   - Verify output structure and data types
   - Check for errors in the results

2. **Monitor Job Health**:
   - Check for conversion errors
   - Monitor SU (Streaming Unit) utilization  
   - Verify output data quality

3. **Validate Business Logic**:
   - Confirm calculations are correct
   - Test edge cases (nulls, extremes)
   - Verify conditional logic

## 📚 Key Concepts Learned

1. **SAQL Syntax**: SQL-like language with streaming extensions
2. **Data Types**: Working with various data types in streaming context
3. **Functions**: String, math, date/time, and conditional functions
4. **JSON Handling**: Accessing nested properties and arrays
5. **Query Testing**: Using built-in test features
6. **Performance**: Writing efficient streaming queries

## 🎯 Lab Success Criteria

✅ Successfully tested at least 5 different query patterns  
✅ Demonstrated understanding of data type conversions  
✅ Implemented conditional logic with CASE statements  
✅ Worked with nested JSON properties  
✅ Applied filtering and data validation  
✅ Used built-in functions for string, math, and date operations  
✅ Created queries with multiple outputs (if configured)  

## 🚀 Next Steps

Great work! You now understand the fundamentals of Stream Analytics Query Language.

**Next Lab**: [Lab 3: Data Manipulation Functions](./lab-03-data-manipulation.md)

In the next lab, you'll dive deeper into:
- DateTime manipulation and time zones
- Advanced mathematical functions
- String processing and pattern matching
- Data transformation techniques

## 📖 Additional Resources

- [Stream Analytics Query Language Reference](https://docs.microsoft.com/stream-analytics-query/)
- [SAQL Built-in Functions](https://docs.microsoft.com/azure/stream-analytics/stream-analytics-stream-analytics-query-patterns)
- [JSON Functions in Stream Analytics](https://docs.microsoft.com/azure/stream-analytics/stream-analytics-parse-json-and-avro-data)
- [Data Types in Stream Analytics](https://docs.microsoft.com/azure/stream-analytics/stream-analytics-stream-analytics-query-patterns#data-types)

---

**Estimated Completion Time**: 60-90 minutes  
**Difficulty Level**: Beginner to Intermediate  
**Cost Impact**: ~$2-3 for the duration of the lab
