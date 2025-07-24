# Lab 3: Data Manipulation Functions

## 🎯 Lab Objectives

In this lab, you will:
- Master DateTime functions and time zone handling
- Work with advanced mathematical functions
- Implement string manipulation and pattern matching
- Learn data conversion and validation techniques
- Practice data transformation scenarios
- Handle edge cases and null values

## 📋 Prerequisites

- Completed [Lab 2: SAQL Overview](./lab-02-saql-overview.md)
- Understanding of basic SAQL syntax
- Running Stream Analytics job with sample data

## 🕒 DateTime Functions

DateTime manipulation is crucial for time-series data processing.

### Step 1: Basic DateTime Operations

#### Query 1: DateTime Extraction
```sql
-- Extract different parts of datetime
SELECT 
    deviceId,
    timestamp,
    -- Date parts
    DATEPART(year, timestamp) AS EventYear,
    DATEPART(month, timestamp) AS EventMonth,
    DATEPART(day, timestamp) AS EventDay,
    DATEPART(hour, timestamp) AS EventHour,
    DATEPART(minute, timestamp) AS EventMinute,
    DATEPART(second, timestamp) AS EventSecond,
    DATEPART(millisecond, timestamp) AS EventMillisecond,
    DATEPART(dayofweek, timestamp) AS DayOfWeek,
    DATEPART(dayofyear, timestamp) AS DayOfYear,
    DATEPART(week, timestamp) AS WeekOfYear
INTO [blob-output]
FROM [telemetry-input]
```

#### Query 2: DateTime Calculations
```sql
-- DateTime arithmetic and calculations
SELECT 
    deviceId,
    timestamp,
    System.Timestamp() AS ProcessingTime,
    -- Time differences
    DATEDIFF(second, timestamp, System.Timestamp()) AS ProcessingDelaySeconds,
    DATEDIFF(minute, timestamp, System.Timestamp()) AS ProcessingDelayMinutes,
    DATEDIFF(hour, timestamp, System.Timestamp()) AS ProcessingDelayHours,
    -- Date additions
    DATEADD(hour, 1, timestamp) AS OneHourLater,
    DATEADD(day, -7, timestamp) AS OneWeekEarlier,
    DATEADD(minute, 30, timestamp) AS ThirtyMinutesLater
INTO [blob-output]
FROM [telemetry-input]
```

#### Query 3: DateTime Formatting
```sql
-- Format datetime for different outputs
SELECT 
    deviceId,
    timestamp,
    -- Different format options
    CONCAT(
        CAST(DATEPART(year, timestamp) AS nvarchar(max)), '-',
        RIGHT('00' + CAST(DATEPART(month, timestamp) AS nvarchar(max)), 2), '-',
        RIGHT('00' + CAST(DATEPART(day, timestamp) AS nvarchar(max)), 2)
    ) AS DateString,
    CONCAT(
        RIGHT('00' + CAST(DATEPART(hour, timestamp) AS nvarchar(max)), 2), ':',
        RIGHT('00' + CAST(DATEPART(minute, timestamp) AS nvarchar(max)), 2), ':',
        RIGHT('00' + CAST(DATEPART(second, timestamp) AS nvarchar(max)), 2)
    ) AS TimeString,
    -- Day names
    CASE DATEPART(weekday, timestamp)
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday' 
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
        ELSE -1
    END AS DayName
INTO [blob-output]
FROM [telemetry-input]
```

### Step 2: Time Zone Handling

#### Query 4: UTC and Time Zone Conversions
```sql
-- Working with different time zones
SELECT 
    deviceId,
    timestamp AS UtcTimestamp,
    -- Convert to different time zones (offset-based)
    DATEADD(hour, -8, timestamp) AS PacificTime,
    DATEADD(hour, -5, timestamp) AS EasternTime,
    DATEADD(hour, 1, timestamp) AS CentralEuropeanTime,
    DATEADD(hour, 9, timestamp) AS JapanTime,
    -- Business hours detection (UTC)
    CASE 
        WHEN DATEPART(hour, timestamp) BETWEEN 9 AND 17 THEN 'Business Hours'
        ELSE 'After Hours'
    END AS BusinessHoursUTC,
    -- Business hours detection (EST)
    CASE 
        WHEN DATEPART(hour, DATEADD(hour, -5, timestamp)) BETWEEN 9 AND 17 THEN 'Business Hours'
        ELSE 'After Hours'
    END AS BusinessHoursEST
INTO [blob-output]
FROM [telemetry-input]
```

#### Query 5: Time-Based Filtering
```sql
-- Filter events based on time criteria
SELECT 
    deviceId,
    timestamp,
    temperature,
    'BUSINESS_HOURS_DATA' AS DataCategory
INTO [blob-output]
FROM [telemetry-input]
WHERE 
    DATEPART(weekday, timestamp) BETWEEN 2 AND 6  -- Monday to Friday
    AND DATEPART(hour, DATEADD(hour, -5, timestamp)) BETWEEN 9 AND 17  -- 9 AM to 5 PM EST
```

## 🔢 Mathematical Functions

### Step 3: Basic Mathematical Operations

#### Query 6: Arithmetic and Basic Functions
```sql
-- Mathematical calculations and functions
SELECT 
    deviceId,
    temperature,
    humidity,
    pressure,
    -- Basic arithmetic
    temperature + humidity AS TempHumiditySum,
    temperature * 1.8 + 32 AS TempFahrenheit,
    pressure / 1000.0 AS PressureKPa,
    -- Mathematical functions
    ABS(temperature - 20) AS TempDeviationFromTwenty,
    ROUND(temperature, 1) AS TempRounded1Decimal,
    ROUND(humidity, 0) AS HumidityRoundedInt,
    CEILING(temperature) AS TempCeiling,
    FLOOR(humidity) AS HumidityFloor,
    POWER(temperature, 2) AS TempSquared,
    SQRT(pressure) AS PressureSqrt,
    EXP(temperature / 100) AS TempExponential,
    LOG(pressure) AS PressureLog
INTO [blob-output]
FROM [telemetry-input]
WHERE temperature IS NOT NULL AND pressure > 0
```

#### Query 7: Advanced Mathematical Functions
```sql
-- Trigonometric and advanced math functions
SELECT 
    deviceId,
    temperature,
    location.lat AS Latitude,
    location.lon AS Longitude,
    -- Trigonometric functions (working with coordinates)
    SIN(location.lat * PI() / 180) AS LatitudeSine,
    COS(location.lon * PI() / 180) AS LongitudeCosine,
    TAN(location.lat * PI() / 180) AS LatitudeTangent,
    -- Statistical functions
    SIGN(temperature - 25) AS TempSign,
    -- Min/Max with multiple values
    CASE 
        WHEN temperature > humidity THEN temperature
        ELSE humidity
    END AS MaxTempHumidity,
    -- Modulo operations
    CAST(temperature AS bigint) % 10 AS TempMod10
INTO [blob-output]
FROM [telemetry-input]
WHERE location.lat IS NOT NULL AND location.lon IS NOT NULL
```

### Step 4: Statistical Calculations

#### Query 8: Moving Averages and Ranges
```sql
-- Calculate statistical measures
SELECT 
    deviceId,
    timestamp,
    temperature,
    humidity,
    pressure,
    -- Heat index calculation (simplified)
    CASE 
        WHEN temperature >= 26.67 THEN
            temperature + 
            0.5555 * (6.11 * EXP(5417.7530 * ((1/273.16) - (1/(273.16 + temperature)))) * (humidity/100) - 10.0)
        ELSE temperature
    END AS HeatIndex,
    -- Dew point calculation (simplified Magnus formula)
    temperature - ((100 - humidity) / 5) AS DewPointApprox,
    -- Comfort index based on temperature and humidity
    CASE 
        WHEN temperature BETWEEN 20 AND 26 AND humidity BETWEEN 40 AND 70 THEN 'Comfortable'
        WHEN temperature > 30 OR humidity > 80 THEN 'Uncomfortable_Hot_Humid'
        WHEN temperature < 15 OR humidity < 30 THEN 'Uncomfortable_Cold_Dry'
        ELSE 'Moderate'
    END AS ComfortLevel
INTO [blob-output]
FROM [telemetry-input]
```

## 🔤 String Functions

### Step 5: String Manipulation

#### Query 9: Basic String Operations
```sql
-- String manipulation functions
SELECT 
    deviceId,
    -- String functions
    UPPER(deviceId) AS DeviceIdUpper,
    LOWER(deviceId) AS DeviceIdLower,
    LEN(deviceId) AS DeviceIdLength,
    REVERSE(deviceId) AS DeviceIdReversed,
    -- Substring operations
    LEFT(deviceId, 6) AS DevicePrefix,
    RIGHT(deviceId, 3) AS DeviceNumber,
    SUBSTRING(deviceId, 8, 3) AS DeviceNumeric,
    -- String replacement
    REPLACE(deviceId, 'device-', 'sensor_') AS ModifiedDeviceId,
    -- Concatenation
    CONCAT(deviceId, '_', CAST(DATEPART(hour, timestamp) AS nvarchar(max))) AS DeviceHourId,
    CONCAT('Device: ', deviceId, ' | Temp: ', CAST(temperature AS nvarchar(max))) AS DeviceInfo
INTO [blob-output]
FROM [telemetry-input]
```

#### Query 10: Pattern Matching and Validation
```sql
-- Pattern matching and string validation
SELECT 
    deviceId,
    temperature,
    -- Pattern matching with LIKE
    CASE 
        WHEN deviceId LIKE 'device-00%' THEN 'Group A'
        WHEN deviceId LIKE 'device-01%' THEN 'Group B'
        WHEN deviceId LIKE 'device-02%' THEN 'Group C'
        ELSE 'Other'
    END AS DeviceGroup,
    -- String validation
    CASE 
        WHEN LEN(deviceId) = 10 AND deviceId LIKE 'device-___' THEN 'Valid Format'
        ELSE 'Invalid Format'
    END AS DeviceIdValidation,
    -- Extract numeric part
    CASE 
        WHEN deviceId LIKE 'device-___' THEN 
            TRY_CAST(RIGHT(deviceId, 3) AS bigint)
        ELSE NULL
    END AS DeviceNumber,
    -- Padding
    RIGHT('000' + CAST(DATEPART(dayofyear, timestamp) AS nvarchar(max)), 3) AS DayOfYearPadded
INTO [blob-output]
FROM [telemetry-input]
```

#### Query 11: Advanced String Processing
```sql
-- Advanced string operations and parsing
SELECT 
    deviceId,
    timestamp,
    -- Create formatted identifiers
    CONCAT(
        LEFT(deviceId, 6),
        '_',
        CAST(DATEPART(year, timestamp) AS nvarchar(max)),
        RIGHT('00' + CAST(DATEPART(month, timestamp) AS nvarchar(max)), 2),
        RIGHT('00' + CAST(DATEPART(day, timestamp) AS nvarchar(max)), 2)
    ) AS DailyDeviceId,
    -- Create location string from coordinates
    CASE 
        WHEN location.lat IS NOT NULL AND location.lon IS NOT NULL THEN
            CONCAT(
                CAST(ROUND(location.lat, 4) AS nvarchar(max)), 
                ',', 
                CAST(ROUND(location.lon, 4) AS nvarchar(max))
            )
        ELSE 'Unknown Location'
    END AS LocationString,
    -- Create summary description
    CONCAT(
        'Device ', deviceId, 
        ' reported ', CAST(ROUND(temperature, 1) AS nvarchar(max)), '°C',
        ' and ', CAST(ROUND(humidity, 1) AS nvarchar(max)), '% humidity',
        ' at ', CAST(DATEPART(hour, timestamp) AS nvarchar(max)), ':',
        RIGHT('00' + CAST(DATEPART(minute, timestamp) AS nvarchar(max)), 2)
    ) AS ReadingSummary
INTO [blob-output]
FROM [telemetry-input]
```

## 🔄 Data Conversion and Validation

### Step 6: Type Conversions

#### Query 12: Safe Type Conversions
```sql
-- Safe data type conversions with error handling
SELECT 
    deviceId,
    timestamp,
    temperature,
    -- Safe conversions with TRY_CAST
    TRY_CAST(temperature AS bigint) AS TempInteger,
    TRY_CAST(humidity AS nvarchar(max)) AS HumidityString,
    TRY_CAST(LEFT(deviceId, 6) AS nvarchar(max)) AS DevicePrefix,
    -- Conditional conversions
    CASE 
        WHEN temperature IS NOT NULL THEN CAST(temperature AS nvarchar(max))
        ELSE 'No Reading'
    END AS TempDisplay,
    -- Number formatting
    CASE 
        WHEN temperature IS NOT NULL THEN 
            CONCAT(CAST(ROUND(temperature, 1) AS nvarchar(max)), ' °C')
        ELSE 'N/A'
    END AS FormattedTemp,
    -- Boolean conversions
    CASE 
        WHEN temperature > 25 THEN CAST(1 AS bit)
        ELSE CAST(0 AS bit)
    END AS IsWarm
INTO [blob-output]
FROM [telemetry-input]
```

### Step 7: Data Validation and Cleansing

#### Query 13: Comprehensive Data Validation
```sql
-- Data quality validation and cleansing
SELECT 
    deviceId,
    timestamp,
    temperature,
    humidity,
    pressure,
    -- Validation flags
    CASE 
        WHEN temperature IS NULL THEN 'Missing'
        WHEN temperature < -50 OR temperature > 100 THEN 'Out of Range'
        ELSE 'Valid'
    END AS TempValidation,
    CASE 
        WHEN humidity IS NULL THEN 'Missing'
        WHEN humidity < 0 OR humidity > 100 THEN 'Out of Range'
        ELSE 'Valid'
    END AS HumidityValidation,
    CASE 
        WHEN pressure IS NULL THEN 'Missing'
        WHEN pressure < 800 OR pressure > 1200 THEN 'Out of Range'
        ELSE 'Valid'
    END AS PressureValidation,
    -- Data quality score
    CASE 
        WHEN temperature IS NOT NULL AND temperature BETWEEN -50 AND 100 THEN 1 ELSE 0
    END +
    CASE 
        WHEN humidity IS NOT NULL AND humidity BETWEEN 0 AND 100 THEN 1 ELSE 0
    END +
    CASE 
        WHEN pressure IS NOT NULL AND pressure BETWEEN 800 AND 1200 THEN 1 ELSE 0
    END AS QualityScore,
    -- Cleansed values
    CASE 
        WHEN temperature IS NULL OR temperature < -50 OR temperature > 100 THEN 20.0
        ELSE temperature
    END AS CleanedTemperature
INTO [blob-output]
FROM [telemetry-input]
```

## 🧮 Practical Transformation Scenarios

### Step 8: Real-World Data Transformations

#### Query 14: Sensor Data Normalization
```sql
-- Normalize and standardize sensor data
SELECT 
    deviceId,
    timestamp,
    -- Normalized temperature (0-1 scale for range -40 to 60°C)
    CASE 
        WHEN temperature IS NOT NULL THEN
            (temperature + 40.0) / 100.0
        ELSE 0.5
    END AS TempNormalized,
    -- Humidity percentage to decimal
    ISNULL(humidity / 100.0, 0.5) AS HumidityDecimal,
    -- Pressure normalized (0-1 scale for range 800-1200 hPa)
    CASE 
        WHEN pressure IS NOT NULL THEN
            (pressure - 800.0) / 400.0
        ELSE 0.5
    END AS PressureNormalized,
    -- Z-score calculation (assuming mean=25, std=10 for temperature)
    CASE 
        WHEN temperature IS NOT NULL THEN
            (temperature - 25.0) / 10.0
        ELSE 0
    END AS TempZScore,
    -- Min-max scaling to 0-100 range
    CASE 
        WHEN temperature IS NOT NULL THEN
            ((temperature + 40.0) / 100.0) * 100
        ELSE 50
    END AS TempScaled0to100
INTO [blob-output]
FROM [telemetry-input]
```

#### Query 15: Multi-Sensor Data Fusion
```sql
-- Combine multiple sensor readings into derived metrics
SELECT 
    deviceId,
    timestamp,
    temperature,
    humidity,
    pressure,
    -- Composite comfort index
    CASE 
        WHEN temperature IS NOT NULL AND humidity IS NOT NULL THEN
            (
                -- Temperature component (optimal around 22°C)
                (1.0 - ABS(temperature - 22.0) / 30.0) * 0.5 +
                -- Humidity component (optimal around 50%)
                (1.0 - ABS(humidity - 50.0) / 50.0) * 0.3 +
                -- Pressure component (optimal around 1013 hPa)
                (1.0 - ABS(pressure - 1013.0) / 200.0) * 0.2
            ) * 100
        ELSE 50
    END AS ComfortIndex,
    -- Environmental stress indicator
    CASE 
        WHEN temperature > 35 OR humidity > 90 OR pressure < 950 THEN 'High Stress'
        WHEN temperature > 30 OR humidity > 75 OR pressure < 980 THEN 'Moderate Stress'
        ELSE 'Low Stress'
    END AS EnvironmentalStress,
    -- Equipment operational rating
    CASE 
        WHEN temperature BETWEEN 15 AND 30 AND humidity BETWEEN 30 AND 70 THEN 'Optimal'
        WHEN temperature BETWEEN 10 AND 35 AND humidity BETWEEN 20 AND 80 THEN 'Good'
        WHEN temperature BETWEEN 5 AND 40 AND humidity BETWEEN 10 AND 90 THEN 'Acceptable'
        ELSE 'Poor'
    END AS OperationalRating
INTO [blob-output]
FROM [telemetry-input]
```

## 🧪 Practice Exercises

### Exercise 1: Time Zone Dashboard
Create queries that:
- Show readings in multiple time zones simultaneously
- Categorize data by business hours in different regions
- Calculate time since last reading per device

### Exercise 2: Data Quality Monitor
Develop queries that:
- Identify sensors with consistent out-of-range values
- Calculate data completeness percentages
- Generate data quality reports

### Exercise 3: Advanced Transformations
Build queries that:
- Implement custom weather indexes (heat index, wind chill, etc.)
- Create geospatial distance calculations
- Develop anomaly scoring algorithms

## 🐛 Common Issues and Solutions

### Issue 1: Division by Zero
```sql
-- ❌ Problem: Division by zero
SELECT temperature / (humidity - humidity) FROM [telemetry-input]

-- ✅ Solution: Check for zero before division
SELECT 
    CASE 
        WHEN humidity != 0 THEN temperature / humidity
        ELSE NULL
    END AS TempHumidityRatio
FROM [telemetry-input]
```

### Issue 2: Invalid Date Operations
```sql
-- ❌ Problem: Invalid date arithmetic
SELECT DATEADD(day, humidity, timestamp) FROM [telemetry-input]

-- ✅ Solution: Validate inputs
SELECT 
    CASE 
        WHEN humidity IS NOT NULL AND humidity BETWEEN 0 AND 365 THEN
            DATEADD(day, CAST(humidity AS bigint), timestamp)
        ELSE timestamp
    END AS AdjustedDate
FROM [telemetry-input]
```

### Issue 3: String Function Errors
```sql
-- ❌ Problem: SUBSTRING with invalid parameters
SELECT SUBSTRING(deviceId, -1, 5) FROM [telemetry-input]

-- ✅ Solution: Validate string operations
SELECT 
    CASE 
        WHEN LEN(deviceId) >= 5 THEN SUBSTRING(deviceId, 1, 5)
        ELSE deviceId
    END AS SafeSubstring
FROM [telemetry-input]
```

## 🎯 Lab Success Criteria

✅ Successfully implemented DateTime extraction and formatting  
✅ Applied mathematical functions for data calculations  
✅ Used string functions for data manipulation  
✅ Implemented safe type conversions  
✅ Created data validation and cleansing logic  
✅ Built composite metrics from multiple sensors  
✅ Handled edge cases and null values appropriately  

## 🚀 Next Steps

Excellent! You've mastered data manipulation functions in Stream Analytics.

**Next Lab**: [Lab 4: Aggregate Functions](./lab-04-aggregate-functions.md)

In the next lab, you'll learn about:
- GROUP BY operations
- COUNT, SUM, AVG, MIN, MAX functions
- Statistical aggregations
- Custom aggregation patterns

## 📖 Additional Resources

- [SAQL Date and Time Functions](https://docs.microsoft.com/azure/stream-analytics/stream-analytics-stream-analytics-query-patterns#date-and-time-functions)
- [Mathematical Functions in Stream Analytics](https://docs.microsoft.com/azure/stream-analytics/stream-analytics-stream-analytics-query-patterns#mathematical-functions)
- [String Functions Reference](https://docs.microsoft.com/azure/stream-analytics/stream-analytics-stream-analytics-query-patterns#string-functions)
- [Type Conversion Functions](https://docs.microsoft.com/azure/stream-analytics/stream-analytics-stream-analytics-query-patterns#conversion-functions)

---

**Estimated Completion Time**: 75-90 minutes  
**Difficulty Level**: Intermediate  
**Cost Impact**: ~$2-4 for the duration of the lab
