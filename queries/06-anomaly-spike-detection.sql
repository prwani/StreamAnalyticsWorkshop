-- Lab 6: Anomaly Detection - Spike and Dip Detection
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
