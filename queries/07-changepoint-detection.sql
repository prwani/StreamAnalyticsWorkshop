-- Lab 6: Anomaly Detection - Change Point Detection
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
