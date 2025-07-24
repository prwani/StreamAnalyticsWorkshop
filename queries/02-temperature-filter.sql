-- Filter high temperature readings
SELECT 
    deviceId,
    timestamp,
    temperature,
    humidity,
    pressure,
    'HIGH_TEMP_ALERT' AS AlertType,
    System.Timestamp() AS ProcessedTime
INTO [blob-output]
FROM [telemetry-input]
WHERE temperature > 30
