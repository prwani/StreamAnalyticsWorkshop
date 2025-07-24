-- Lab 10: IoT Edge Processing
-- Local data filtering and aggregation at the edge
SELECT 
    System.Timestamp() AS windowEnd,
    COUNT(*) AS eventCount,
    AVG(temperature) AS avgTemperature,
    MIN(temperature) AS minTemperature,
    MAX(temperature) AS maxTemperature,
    AVG(humidity) AS avgHumidity,
    AVG(pressure) AS avgPressure,
    -- Send alert flag if any reading was critical
    MAX(CASE WHEN temperature > 35 OR temperature < 5 THEN 1 ELSE 0 END) AS hasCriticalReading,
    -- Count of different alert types
    SUM(CASE WHEN temperature > 35 THEN 1 ELSE 0 END) AS highTempCount,
    SUM(CASE WHEN temperature < 5 THEN 1 ELSE 0 END) AS lowTempCount
INTO [edge-output]
FROM [edge-input]
GROUP BY TumblingWindow(minute, 5)
