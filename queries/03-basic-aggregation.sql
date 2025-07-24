-- Basic aggregations over 5-minute tumbling windows
SELECT 
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS EventCount,
    AVG(temperature) AS AvgTemperature,
    MIN(temperature) AS MinTemperature,
    MAX(temperature) AS MaxTemperature,
    AVG(humidity) AS AvgHumidity,
    AVG(pressure) AS AvgPressure
INTO [blob-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY TumblingWindow(minute, 5)
