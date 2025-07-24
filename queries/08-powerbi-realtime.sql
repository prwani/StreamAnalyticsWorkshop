-- Lab 7: Power BI Real-time Visualization
-- Real-time device telemetry for Power BI dashboard
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
